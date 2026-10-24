"""Regras das mensagens enviadas aos contatos de um paciente."""

from services.paciente.registro_paciente_service import (
    RegistroPacienteService,
    texto_preenchido,
)


class ComunicadoService(RegistroPacienteService):
    """Garante que um comunicado tenha mensagem e destinatários."""

    # Identificador usado nas rotas e na tabela compartilhada.
    RECURSO = "comunicados"
    # Não existe comunicado útil sem conteúdo e sem alguém para recebê-lo.
    CAMPOS_OBRIGATORIOS = frozenset({"destinatarios", "mensagem"})

    def _normalizar(self, dados, parcial=False):
        """Valida o texto da mensagem e a lista de contatos selecionados."""
        dados = super()._normalizar(dados, parcial)
        if dados is None:
            return None

        # Remove espaços nas extremidades e rejeita mensagens em branco.
        if "mensagem" in dados:
            if not texto_preenchido(dados["mensagem"]):
                return None
            dados["mensagem"] = dados["mensagem"].strip()

        # Cada destinatário chega do Flutter como um objeto JSON contendo seus
        # dados. A lista precisa possuir pelo menos um desses objetos.
        if "destinatarios" in dados:
            destinatarios = dados["destinatarios"]
            if (
                not isinstance(destinatarios, list)
                or not destinatarios
                or not all(isinstance(item, dict) for item in destinatarios)
            ):
                return None
        # O estado de entrega nao pode ser falsificado pelo cliente.
        if parcial:
            dados.pop('status', None)
            dados.pop('tentativas', None)
            dados.pop('enviado_em', None)
            dados.pop('erro_envio', None)
            if not dados:
                return None
        else:
            dados['status'] = 'pendente'
            dados['tentativas'] = 0
        return dados
