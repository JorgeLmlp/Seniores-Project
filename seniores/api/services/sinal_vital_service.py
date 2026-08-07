from datetime import datetime

from models.paciente.paciente import SinalVital


class SinalVitalService:
    """Regras de cadastro dos sinais vitais medidos."""

    CAMPOS = ("freq_cardiaca", "saturacao", "pressao_art", "glicemia", "temperatura")

    def criar(self, info):
        dados = {campo: info.get(campo) for campo in self.CAMPOS}
        if not any(dados.values()):
            return None, 400

        data = info.get("data")
        if data:
            try:
                dados["data"] = datetime.fromisoformat(data.replace("Z", "+00:00"))
            except (TypeError, ValueError):
                return None, 400

        sinal_vital = SinalVital.criar(dados)
        return (sinal_vital, 201) if sinal_vital else (None, 500)
