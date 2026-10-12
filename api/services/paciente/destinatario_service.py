"""Regras dos contatos que podem receber comunicados do paciente."""

from services.paciente.registro_paciente_service import (
    RegistroPacienteService,
    texto_preenchido,
)


class DestinatarioService(RegistroPacienteService):
    """Valida os dados mínimos necessários para identificar um contato."""

    # Identificador persistido na coluna `recurso`.
    RECURSO = "destinatarios"
    # Sem esses campos o contato não pode ser exibido nem selecionado na tela.
    CAMPOS_OBRIGATORIOS = frozenset({"nome", "vinculo", "telefone"})

    def _normalizar(self, dados, parcial=False):
        """Rejeita textos vazios e remove espaços desnecessários."""
        dados = super()._normalizar(dados, parcial)
        if dados is None:
            return None

        # A máscara e a formatação do telefone ficam no Flutter; aqui apenas
        # garantimos que um valor textual foi realmente informado.
        for campo in ("nome", "vinculo", "telefone"):
            if campo in dados and not texto_preenchido(dados[campo]):
                return None
            if campo in dados:
                dados[campo] = dados[campo].strip()
        return dados
