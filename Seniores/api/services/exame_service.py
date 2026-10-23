from models.paciente.exame import Exame
from models.paciente.paciente import Paciente


class ExameService:
    CAMPOS = {"nome", "data", "laboratorio", "local", "observacoes", "documento_url"}

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Exame.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info)
        if not dados.get("nome") or not dados.get("data"):
            return None, 400
        exame = Exame.criar(paciente_id, dados)
        return (exame, 201) if exame else (None, 500)

    def buscar(self, exame_id):
        exame = Exame.buscar_por_id(exame_id)
        return (exame, 200) if exame else (None, 404)

    def atualizar(self, exame_id, info):
        exame, status = self.buscar(exame_id)
        if status != 200:
            return None, status
        dados = self._dados(info)
        if "nome" in dados and not dados["nome"]:
            return None, 400
        if "data" in dados and not dados["data"]:
            return None, 400
        exame = exame.atualizar(dados)
        return (exame, 200) if exame else (None, 500)

    def deletar(self, exame_id):
        exame, status = self.buscar(exame_id)
        if status != 200:
            return None, status
        return (None, 204) if exame.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        return {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
