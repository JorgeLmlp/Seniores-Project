"""Regras específicas dos exames associados a um paciente."""

from services.registro_paciente_service import (
    RegistroPacienteService,
    data_iso_valida,
    texto_preenchido,
)


class ExameService(RegistroPacienteService):
    """Valida exames antes de usar as operações compartilhadas de CRUD."""

    # Valor usado para gravar e filtrar este tipo na tabela `registros_app`.
    RECURSO = "exames"
    # Um novo exame precisa informar o que é, onde e quando será realizado.
    CAMPOS_OBRIGATORIOS = frozenset({"nomeExame", "local", "dataHora"})

    def _normalizar(self, dados, parcial=False):
        """Normaliza os textos e confere data e estados booleanos do exame."""
        dados = super()._normalizar(dados, parcial)
        if dados is None:
            return None

        # Não aceita nome ou local contendo somente espaços.
        for campo in ("nomeExame", "local"):
            if campo in dados and not texto_preenchido(dados[campo]):
                return None
            if campo in dados:
                dados[campo] = dados[campo].strip()

        # `dataHora` deve usar o padrão ISO 8601 enviado pelo Flutter.
        if "dataHora" in dados and not data_iso_valida(dados["dataHora"]):
            return None

        # Esses campos controlam em qual lista/tela o exame será apresentado.
        for campo in ("historico", "concluido"):
            if campo in dados and not isinstance(dados[campo], bool):
                return None
        return dados
