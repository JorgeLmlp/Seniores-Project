from models.paciente.consulta import Consulta
from models.paciente.paciente import Paciente


class ConsultaService:
    CAMPOS = {
        "titulo", "especialidade", "profissional", "data", "hora", "local",
        "telefone", "observacoes",
    }

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Consulta.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info)
        if not dados.get("titulo") or not dados.get("data"):
            return None, 400
        consulta = Consulta.criar(paciente_id, dados)
        return (consulta, 201) if consulta else (None, 500)

    def buscar(self, consulta_id):
        consulta = Consulta.buscar_por_id(consulta_id)
        return (consulta, 200) if consulta else (None, 404)

    def atualizar(self, consulta_id, info):
        consulta, status = self.buscar(consulta_id)
        if status != 200:
            return None, status
        dados = self._dados(info)
        if "titulo" in dados and not dados["titulo"]:
            return None, 400
        if "data" in dados and not dados["data"]:
            return None, 400
        consulta = consulta.atualizar(dados)
        return (consulta, 200) if consulta else (None, 500)

    def deletar(self, consulta_id):
        consulta, status = self.buscar(consulta_id)
        if status != 200:
            return None, status
        return (None, 204) if consulta.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        return {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
