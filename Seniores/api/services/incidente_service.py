from models.paciente.incidente import Incidente
from models.paciente.paciente import Paciente


class IncidenteService:
    CAMPOS = {
        "tipo", "data_hora", "descricao", "gravidade", "providencias", "resolvido",
    }

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Incidente.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info)
        if not dados.get("tipo") or not dados.get("data_hora") or not dados.get("descricao"):
            return None, 400
        incidente = Incidente.criar(paciente_id, dados)
        return (incidente, 201) if incidente else (None, 500)

    def buscar(self, incidente_id):
        incidente = Incidente.buscar_por_id(incidente_id)
        return (incidente, 200) if incidente else (None, 404)

    def atualizar(self, incidente_id, info):
        incidente, status = self.buscar(incidente_id)
        if status != 200:
            return None, status
        dados = self._dados(info)
        for campo in ("tipo", "data_hora", "descricao"):
            if campo in dados and not dados[campo]:
                return None, 400
        incidente = incidente.atualizar(dados)
        return (incidente, 200) if incidente else (None, 500)

    def deletar(self, incidente_id):
        incidente, status = self.buscar(incidente_id)
        if status != 200:
            return None, status
        return (None, 204) if incidente.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        return {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
