from pathlib import Path
from uuid import uuid4

from werkzeug.utils import secure_filename

from extensions import db
from models.paciente.remedio import Remedio
from services.documento_exame_service import current_upload_folder


class FotoMedicamentoService:
    EXTENSOES = {"jpg", "jpeg", "png", "webp"}
    MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
    MIME_POR_EXTENSAO = {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }
    LIMITE_BYTES = 5 * 1024 * 1024

    def salvar(self, medicamento_id, arquivo):
        medicamento = Remedio.buscar_por_id(medicamento_id)
        if not medicamento:
            return None, "medicamento_nao_encontrado"
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

        pasta = Path(current_upload_folder()) / "medicamentos"
        pasta.mkdir(parents=True, exist_ok=True)
        nome_armazenado = f"{uuid4().hex}.{extensao}"
        caminho = pasta / nome_armazenado
        caminho.write_bytes(conteudo)
        caminho_anterior = (
            pasta / medicamento.foto_nome_armazenado
            if medicamento.foto_nome_armazenado
            else None
        )
        medicamento.foto_nome = nome
        medicamento.foto_nome_armazenado = nome_armazenado
        medicamento.foto_mime = mime_type
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            caminho.unlink(missing_ok=True)
            return None, "erro_interno"
        if caminho_anterior:
            caminho_anterior.unlink(missing_ok=True)
        return medicamento, None

    def remover(self, medicamento_id):
        medicamento = Remedio.buscar_por_id(medicamento_id)
        if not medicamento:
            return False, 404
        if not medicamento.foto_nome_armazenado:
            return True, 204
        caminho = (
            Path(current_upload_folder())
            / "medicamentos"
            / medicamento.foto_nome_armazenado
        )
        medicamento.foto_nome = None
        medicamento.foto_nome_armazenado = None
        medicamento.foto_mime = None
        try:
            db.session.commit()
            caminho.unlink(missing_ok=True)
            return True, 204
        except Exception:
            db.session.rollback()
            return False, 500

    def caminho(self, medicamento_id):
        medicamento = Remedio.buscar_por_id(medicamento_id)
        if not medicamento or not medicamento.foto_nome_armazenado:
            return None
        caminho = (
            Path(current_upload_folder())
            / "medicamentos"
            / medicamento.foto_nome_armazenado
        )
        return medicamento, caminho if caminho.exists() else None
