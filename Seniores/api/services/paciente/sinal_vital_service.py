from datetime import datetime

from repositories.paciente import sinal_vital_repository


class SinalVitalService:
    """Regras de cadastro dos sinais vitais medidos."""

    CAMPOS = ("freq_cardiaca", "saturacao", "pressao_art", "glicemia", "temperatura")

    def criar(self, paciente_id, info):
        if not sinal_vital_repository.buscar_paciente(paciente_id):
            return None, 404
        dados = {campo: info.get(campo) for campo in self.CAMPOS}
        if not any(dados.values()):
            return None, 400

        data = info.get("data")
        if data:
            try:
                dados["data"] = datetime.fromisoformat(data.replace("Z", "+00:00"))
            except (TypeError, ValueError):
                return None, 400

        sinal_vital = sinal_vital_repository.criar(paciente_id, dados)
        return (sinal_vital, 201) if sinal_vital else (None, 500)

    def listar(self, paciente_id):
        if not sinal_vital_repository.buscar_paciente(paciente_id):
            return None, 404
        return sinal_vital_repository.listar_por_paciente(paciente_id), 200

    def buscar(self, sinal_vital_id):
        sinal_vital = sinal_vital_repository.buscar(sinal_vital_id)
        return (sinal_vital, 200) if sinal_vital else (None, 404)

    def atualizar(self, sinal_vital_id, info):
        sinal_vital, status = self.buscar(sinal_vital_id)
        if status != 200:
            return None, status
        dados = {campo: info[campo] for campo in self.CAMPOS if campo in info}
        if "data" in info:
            try:
                dados["data"] = datetime.fromisoformat(info["data"].replace("Z", "+00:00"))
            except (TypeError, ValueError):
                return None, 400
        if not dados:
            return None, 400
        sinal_vital = sinal_vital_repository.atualizar(sinal_vital, dados)
        return (sinal_vital, 200) if sinal_vital else (None, 500)

    def deletar(self, sinal_vital_id):
        sinal_vital, status = self.buscar(sinal_vital_id)
        if status != 200:
            return None, status
        return (
            (None, 204)
            if sinal_vital_repository.deletar(sinal_vital)
            else (None, 500)
        )
