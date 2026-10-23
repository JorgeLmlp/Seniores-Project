from pathlib import Path
from uuid import uuid4

from werkzeug.utils import secure_filename

from extensions import db
from models.paciente.lesao import Lesao
from services.documento_exame_service import current_upload_folder


class FotoLesaoService:
    EXTENSOES = {"jpg", "jpeg", "png", "webp"}
    MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
    MIME_POR_EXTENSAO = {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }
    LIMITE_BYTES = 5 * 1024 * 1024

    def salvar(self, lesao_id, arquivo):
        lesao = Lesao.buscar_por_id(lesao_id)
        if not lesao:
            return None, "lesao_nao_encontrada"
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

        pasta = Path(current_upload_folder()) / "lesoes"
        pasta.mkdir(parents=True, exist_ok=True)
        nome_armazenado = f"{uuid4().hex}.{extensao}"
        caminho = pasta / nome_armazenado
        caminho.write_bytes(conteudo)
        anterior = pasta / lesao.foto_nome_armazenado if lesao.foto_nome_armazenado else None
        lesao.foto_nome = nome
        lesao.foto_nome_armazenado = nome_armazenado
        lesao.foto_mime = mime_type
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            caminho.unlink(missing_ok=True)
            return None, "erro_interno"
        if anterior:
            anterior.unlink(missing_ok=True)
        return lesao, None

    def remover(self, lesao_id):
        lesao = Lesao.buscar_por_id(lesao_id)
        if not lesao:
            return False, 404
        caminho = (
            Path(current_upload_folder()) / "lesoes" / lesao.foto_nome_armazenado
            if lesao.foto_nome_armazenado
            else None
        )
        lesao.foto_nome = None
        lesao.foto_nome_armazenado = None
        lesao.foto_mime = None
        try:
            db.session.commit()
            if caminho:
                caminho.unlink(missing_ok=True)
            return True, 204
        except Exception:
            db.session.rollback()
            return False, 500

    def caminho(self, lesao_id):
        lesao = Lesao.buscar_por_id(lesao_id)
        if not lesao or not lesao.foto_nome_armazenado:
            return None
        caminho = Path(current_upload_folder()) / "lesoes" / lesao.foto_nome_armazenado
        return lesao, caminho if caminho.exists() else None
