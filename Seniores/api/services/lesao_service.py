from models.paciente.lesao import Lesao
from models.paciente.paciente import Paciente


class LesaoService:
    CAMPOS = {"localizacao", "data_inicio", "descricao", "evolucao"}

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Lesao.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados = self._dados(info)
        if not dados.get("localizacao") or not dados.get("data_inicio") or not dados.get("descricao"):
            return None, 400
        lesao = Lesao.criar(paciente_id, dados)
        return (lesao, 201) if lesao else (None, 500)

    def buscar(self, lesao_id):
        lesao = Lesao.buscar_por_id(lesao_id)
        return (lesao, 200) if lesao else (None, 404)

    def atualizar(self, lesao_id, info):
        lesao, status = self.buscar(lesao_id)
        if status != 200:
            return None, status
        dados = self._dados(info)
        for campo in ("localizacao", "data_inicio", "descricao"):
            if campo in dados and not dados[campo]:
                return None, 400
        lesao = lesao.atualizar(dados)
        return (lesao, 200) if lesao else (None, 500)

    def deletar(self, lesao_id):
        lesao, status = self.buscar(lesao_id)
        if status != 200:
            return None, status
        return (None, 204) if lesao.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        dados = {
            campo: str(info[campo]).strip()
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
        return dados
