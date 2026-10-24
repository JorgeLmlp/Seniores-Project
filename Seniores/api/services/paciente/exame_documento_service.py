from datetime import datetime

from models.paciente.cuidados import ExameDocumento
from repositories import paciente_repository


class ExameDocumentoService:
    TAMANHO_MAXIMO = 10 * 1024 * 1024
    MIMES = {"application/pdf", "image/jpeg", "image/png", "image/webp"}

    def criar(self, paciente_id, formulario, arquivo):
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        dados = self._dados(formulario, arquivo)
        if dados is None:
            return None, 400
        registro = ExameDocumento.criar(paciente_id, dados)
        return (registro, 201) if registro else (None, 500)

    def _dados(self, formulario, arquivo):
        nome = (formulario.get("nome") or "").strip()
        if not nome or not arquivo or arquivo.mimetype not in self.MIMES:
            return None
        conteudo = arquivo.read()
        if not conteudo or len(conteudo) > self.TAMANHO_MAXIMO:
            return None
        dados = {
            "nome": nome, "descricao": formulario.get("descricao"),
            "arquivo": conteudo, "nome_arquivo": arquivo.filename or "exame",
            "mime_type": arquivo.mimetype,
        }
        if formulario.get("data_exame"):
            try:
                dados["data_exame"] = datetime.fromisoformat(formulario["data_exame"].replace("Z", "+00:00"))
            except ValueError:
                return None
        return dados

    def listar(self, paciente_id):
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        return paciente_repository.listar_registros(ExameDocumento, paciente_id), 200

    def buscar(self, registro_id):
        registro = paciente_repository.buscar_registro(ExameDocumento, registro_id)
        return (registro, 200) if registro else (None, 404)

    def deletar(self, registro_id):
        registro, status = self.buscar(registro_id)
        if status != 200:
            return None, status
        return (None, 204) if registro.deletar() else (None, 500)
