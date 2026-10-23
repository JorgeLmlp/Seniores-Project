from models.paciente.gasto import Gasto
from models.paciente.paciente import Paciente


class GastoService:
    CAMPOS = {"descricao", "valor", "data", "categoria", "tipo", "observacoes"}

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return Gasto.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados, valido = self._dados(info)
        if (
            not valido
            or "valor" not in dados
            or not dados.get("descricao")
            or not dados.get("data")
        ):
            return None, 400
        gasto = Gasto.criar(paciente_id, dados)
        return (gasto, 201) if gasto else (None, 500)

    def buscar(self, gasto_id):
        gasto = Gasto.buscar_por_id(gasto_id)
        return (gasto, 200) if gasto else (None, 404)

    def atualizar(self, gasto_id, info):
        gasto, status = self.buscar(gasto_id)
        if status != 200:
            return None, status
        dados, valido = self._dados(info)
        if not valido:
            return None, 400
        for campo in ("descricao", "data"):
            if campo in dados and not dados[campo]:
                return None, 400
        gasto = gasto.atualizar(dados)
        return (gasto, 200) if gasto else (None, 500)

    def deletar(self, gasto_id):
        gasto, status = self.buscar(gasto_id)
        if status != 200:
            return None, status
        return (None, 204) if gasto.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        dados = {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
        if "valor" in dados:
            try:
                dados["valor"] = float(dados["valor"])
            except (TypeError, ValueError):
                return {}, False
            if dados["valor"] < 0:
                return {}, False
        return dados, True
