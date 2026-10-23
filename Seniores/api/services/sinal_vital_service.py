from datetime import datetime
import re

from models.paciente.paciente import SinalVital


class SinalVitalService:
    """Regras de cadastro dos sinais vitais medidos."""

    CAMPOS = ("freq_cardiaca", "saturacao", "pressao_art", "glicemia", "temperatura")

    def criar(self, info):
        dados = {campo: info.get(campo) for campo in self.CAMPOS}
        if not any(dados.values()) or not self._medidas_validas(dados):
            return None, 400

        data = info.get("data")
        if data:
            try:
                dados["data"] = datetime.fromisoformat(data.replace("Z", "+00:00"))
            except (TypeError, ValueError):
                return None, 400

        sinal_vital = SinalVital.criar(dados)
        return (sinal_vital, 201) if sinal_vital else (None, 500)

    def listar(self):
        return SinalVital.listar()

    def atualizar(self, sinal_id, info):
        sinal = SinalVital.buscar_por_id(sinal_id)
        if not sinal:
            return None, 404
        dados = {campo: info.get(campo) for campo in self.CAMPOS if campo in info}
        if not dados and "data" not in info:
            return None, 400
        if dados and not self._medidas_validas(dados):
            return None, 400
        if "data" in info:
            try:
                dados["data"] = datetime.fromisoformat(
                    info["data"].replace("Z", "+00:00")
                )
            except (AttributeError, TypeError, ValueError):
                return None, 400
        sinal = sinal.atualizar(dados)
        return (sinal, 200) if sinal else (None, 500)

    def deletar(self, sinal_id):
        sinal = SinalVital.buscar_por_id(sinal_id)
        if not sinal:
            return None, 404
        return (None, 204) if sinal.deletar() else (None, 500)

    @classmethod
    def _medidas_validas(cls, dados):
        pressao = dados.get("pressao_art")
        if pressao:
            partes = str(pressao).split("/")
            if len(partes) != 2:
                return False
            sistolica = cls._numero(partes[0])
            diastolica = cls._numero(partes[1])
            if (
                sistolica is None
                or diastolica is None
                or not 50 <= sistolica <= 250
                or not 30 <= diastolica <= 150
            ):
                return False

        regras = {
            "glicemia": (20, 600),
            "temperatura": (30, 45),
            "freq_cardiaca": (20, 240),
            "saturacao": (50, 100),
        }
        for campo, (minimo, maximo) in regras.items():
            valor = dados.get(campo)
            if valor in (None, ""):
                continue
            numero = cls._numero(valor)
            if numero is None or not minimo <= numero <= maximo:
                return False
        return True

    @staticmethod
    def _numero(valor):
        normalizado = re.sub(r"[^0-9.\-]", "", str(valor).replace(",", "."))
        try:
            return float(normalizado)
        except ValueError:
            return None
