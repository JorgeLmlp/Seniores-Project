"""Regras específicas dos registros de consultas médicas."""

from services.registro_paciente_service import (
    RegistroPacienteService,
    data_iso_valida,
    texto_preenchido,
)


class ConsultaService(RegistroPacienteService):
    """Valida consultas antes de usar o CRUD da classe base."""

    # Identifica os registros deste service na tabela compartilhada.
    RECURSO = "consultas"
    # Estes três campos são exigidos somente na criação da consulta.
    CAMPOS_OBRIGATORIOS = frozenset({"nomeDoutor", "especialidade", "dataHora"})

    def _normalizar(self, dados, parcial=False):
        """Valida os tipos da consulta e limpa espaços dos textos principais."""
        # Primeiro executa as verificações comuns da classe base.
        dados = super()._normalizar(dados, parcial)
        if dados is None:
            return None

        # Médico e especialidade não podem ser textos vazios.
        for campo in ("nomeDoutor", "especialidade"):
            if campo in dados and not texto_preenchido(dados[campo]):
                return None
            if campo in dados:
                dados[campo] = dados[campo].strip()

        # Evita salvar uma data que o Flutter não conseguirá converter depois.
        if "dataHora" in dados and not data_iso_valida(dados["dataHora"]):
            return None

        # Os estados da consulta precisam ser booleanos JSON: true ou false.
        for campo in ("historico", "concluida"):
            if campo in dados and not isinstance(dados[campo], bool):
                return None

        # Alertas e exames associados são listas compostas somente por textos.
        for campo in ("alertas", "exames"):
            if campo in dados and (
                not isinstance(dados[campo], list)
                or not all(isinstance(item, str) for item in dados[campo])
            ):
                return None
        return dados
