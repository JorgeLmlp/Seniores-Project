from models.paciente.dieta import Dieta
from models.paciente.paciente import Paciente


class DietaService:
    CAMPOS = {"tipo", "data_inicio", "descricao", "restricoes", "observacoes", "ativa"}

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Dieta.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info)
        if not dados.get("tipo") or not dados.get("data_inicio") or not dados.get("descricao"):
            return None, 400
        dieta = Dieta.criar(paciente_id, dados)
        return (dieta, 201) if dieta else (None, 500)

    def buscar(self, dieta_id):
        dieta = Dieta.buscar_por_id(dieta_id)
        return (dieta, 200) if dieta else (None, 404)

    def atualizar(self, dieta_id, info):
        dieta, status = self.buscar(dieta_id)
        if status != 200:
            return None, status
        dados = self._dados(info)
        for campo in ("tipo", "data_inicio", "descricao"):
            if campo in dados and not dados[campo]:
                return None, 400
        dieta = dieta.atualizar(dados)
        return (dieta, 200) if dieta else (None, 500)

    def deletar(self, dieta_id):
        dieta, status = self.buscar(dieta_id)
        if status != 200:
            return None, status
        return (None, 204) if dieta.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        dados = {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
        for campo in ("tipo", "data_inicio", "descricao", "restricoes", "observacoes"):
            if campo in dados:
                dados[campo] = str(dados[campo]).strip()
        if "ativa" in dados and not isinstance(dados["ativa"], bool):
            return {}
        return dados
