import os
from pathlib import Path
from uuid import uuid4

from werkzeug.utils import secure_filename

from extensions import db
from models.paciente.documento_exame import DocumentoExame
from models.paciente.exame import Exame


class DocumentoExameService:
    EXTENSOES = {"pdf", "jpg", "jpeg", "png", "webp"}
    MIME_TYPES = {
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/webp",
    }
    MIME_POR_EXTENSAO = {
        "pdf": "application/pdf",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }
    LIMITE_BYTES = 10 * 1024 * 1024

    def listar(self, exame_id):
        exame = Exame.buscar_por_id(exame_id)
        if not exame:
            return None, 404
        return db.session.scalars(
            db.select(DocumentoExame)
            .where(DocumentoExame.exame_id == exame_id)
            .order_by(DocumentoExame.criado_em.desc())
        ).all(), 200

    def salvar(self, exame_id, arquivo):
        exame = Exame.buscar_por_id(exame_id)
        if not exame:
            return None, "exame_nao_encontrado"
        if not arquivo or not arquivo.filename:
            return None, "arquivo_obrigatorio"

        nome = secure_filename(arquivo.filename)
        extensao = Path(nome).suffix.lower().lstrip(".")
        mime_type = (arquivo.mimetype or "").lower()
        if mime_type in {"", "application/octet-stream"}:
            mime_type = self.MIME_POR_EXTENSAO.get(extensao, "")
        if extensao not in self.EXTENSOES or mime_type not in self.MIME_TYPES:
            return None, "formato_invalido"

        conteudo = arquivo.stream.read(self.LIMITE_BYTES + 1)
        if len(conteudo) > self.LIMITE_BYTES:
            return None, "arquivo_grande"

        pasta = Path(current_upload_folder()) / "exames"
        pasta.mkdir(parents=True, exist_ok=True)
        nome_armazenado = f"{uuid4().hex}.{extensao}"
        caminho = pasta / nome_armazenado
        caminho.write_bytes(conteudo)
        documento = DocumentoExame(
            exame_id=exame_id,
            nome=nome,
            nome_armazenado=nome_armazenado,
            mime_type=mime_type,
            tamanho=len(conteudo),
        )
        try:
            db.session.add(documento)
            db.session.commit()
        except Exception:
            db.session.rollback()
            caminho.unlink(missing_ok=True)
            return None, "erro_interno"
        return documento, None

    def buscar(self, documento_id):
        documento = db.session.get(DocumentoExame, documento_id)
        return documento

    def deletar(self, documento_id):
        documento = self.buscar(documento_id)
        if not documento:
            return False, 404
        caminho = Path(current_upload_folder()) / "exames" / documento.nome_armazenado
        try:
            db.session.delete(documento)
            db.session.commit()
            caminho.unlink(missing_ok=True)
            return True, 204
        except Exception:
            db.session.rollback()
            return False, 500


def current_upload_folder():
    return os.getenv("UPLOAD_FOLDER") or os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "uploads"
    )
