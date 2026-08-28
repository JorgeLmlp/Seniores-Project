"""Regras da escala de cuidadores exibida nas telas do paciente."""

from services.registro_paciente_service import RegistroPacienteService, texto_preenchido


class AgendaCuidadorService(RegistroPacienteService):
    """Valida a escala exibida no Flutter, não o usuário cuidador.

    O cadastro de autenticação do cuidador continua sendo tratado por
    ``UserService``. Aqui ficam apenas função, dias e horários da escala que o
    paciente visualiza no aplicativo.
    """

    # A URL continua sendo `/cuidadores` para manter compatibilidade com o app.
    RECURSO = "cuidadores"
    # A escala precisa identificar a pessoa, a função, os dias e os horários.
    CAMPOS_OBRIGATORIOS = frozenset(
        {"nome", "funcao", "frequencia", "horaInicio", "horaFim"}
    )

    def _normalizar(self, dados, parcial=False):
        """Confere os textos, os sete dias da semana e o estado da escala."""
        dados = super()._normalizar(dados, parcial)
        if dados is None:
            return None

        # Remove espaços externos e rejeita os textos obrigatórios vazios.
        for campo in ("nome", "funcao", "horaInicio", "horaFim"):
            if campo in dados and not texto_preenchido(dados[campo]):
                return None
            if campo in dados:
                dados[campo] = dados[campo].strip()

        # O Flutter envia uma posição booleana para cada dia, começando pelo
        # domingo. Exigir sete itens evita erro ao montar a interface.
        if "frequencia" in dados:
            frequencia = dados["frequencia"]
            if (
                not isinstance(frequencia, list)
                or len(frequencia) != 7
                or not all(isinstance(dia, bool) for dia in frequencia)
            ):
                return None

        # `ativoAgora` não aceita textos como "sim"; deve ser true ou false.
        if "ativoAgora" in dados and not isinstance(dados["ativoAgora"], bool):
            return None
        return dados
