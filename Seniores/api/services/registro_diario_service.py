from models.paciente.paciente import Paciente
from models.paciente.registro_diario import RegistroDiario


class RegistroDiarioService:
    CAMPOS = {
        "data", "humor", "dor", "apetite", "mobilidade", "observacoes",
        "duvidas", "total_incidentes", "tendencia",
    }
    NOTAS = {"humor", "dor", "apetite", "mobilidade"}

    def listar(self, paciente_id):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        return RegistroDiario.listar_por_paciente(paciente_id), 200

    def criar(self, paciente_id, info):
        if not Paciente.buscar_por_id(paciente_id):
            return None, 404
        dados, valido = self._dados(info)
        if not valido or not dados.get("data"):
            return None, 400
        registro = RegistroDiario.criar(paciente_id, dados)
        return (registro, 201) if registro else (None, 500)

    def buscar(self, registro_id):
        registro = RegistroDiario.buscar_por_id(registro_id)
        return (registro, 200) if registro else (None, 404)

    def atualizar(self, registro_id, info):
        registro, status = self.buscar(registro_id)
        if status != 200:
            return None, status
        dados, valido = self._dados(info)
        if not valido or ("data" in dados and not dados["data"]):
            return None, 400
        registro = registro.atualizar(dados)
        return (registro, 200) if registro else (None, 500)

    def deletar(self, registro_id):
        registro, status = self.buscar(registro_id)
        if status != 200:
            return None, status
        return (None, 204) if registro.deletar() else (None, 500)

    @classmethod
    def _dados(cls, info):
        dados = {
            campo: info[campo]
            for campo in cls.CAMPOS
            if campo in info and info[campo] is not None
        }
        for campo in cls.NOTAS:
            if campo in dados:
                try:
                    dados[campo] = float(dados[campo])
                except (TypeError, ValueError):
                    return {}, False
                if not 0 <= dados[campo] <= 10:
                    return {}, False
        if "total_incidentes" in dados:
            valor = dados["total_incidentes"]
            if isinstance(valor, bool) or not isinstance(valor, int) or valor < 0:
                return {}, False
        return dados, True
