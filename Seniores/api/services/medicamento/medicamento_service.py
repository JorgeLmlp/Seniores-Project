from repositories.medicamento import medicamento_repository


class MedicamentoService:
    """Regras para manter a lista de medicamentos de cada paciente."""

    # Apenas estes campos podem ser alterados depois do cadastro.
    CAMPOS_EDITAVEIS = {
        "nome", "descricao", "dosagem", "fabricante", "lote", "quantidade",
        "frequencia", "horarios", "alertas",
    }

    def criar(self, paciente_id, info):
        """Cria o medicamento somente se o paciente da URL existir."""
        paciente = medicamento_repository.buscar_paciente(paciente_id)
        if not paciente:
            return None, 404

        nome = info.get("nome")
        dosagem = info.get("dosagem")
        if not nome or not dosagem:
            return None, 400

        quantidade = info.get("quantidade")
        if quantidade is not None and not self._quantidade_valida(quantidade):
            return None, 400
        if not self._listas_validas(info):
            return None, 400

        medicamento = medicamento_repository.criar(paciente.id, info)
        return (medicamento, 201) if medicamento else (None, 500)

    def listar(self, paciente_id):
        """Impede que uma lista vazia esconda um ID de paciente inexistente."""
        if not medicamento_repository.buscar_paciente(paciente_id):
            return None, 404
        return medicamento_repository.listar_por_paciente(paciente_id), 200

    def buscar(self, medicamento_id):
        """Busca pelo identificador unico do medicamento."""
        medicamento = medicamento_repository.buscar_medicamento(medicamento_id)
        return (medicamento, 200) if medicamento else (None, 404)

    def atualizar(self, medicamento_id, info):
        """Atualiza somente campos permitidos e mantem nome/dosagem obrigatorios."""
        medicamento, status = self.buscar(medicamento_id)
        if status != 200:
            return None, status

        if "quantidade" in info and info["quantidade"] is not None:
            if not self._quantidade_valida(info["quantidade"]):
                return None, 400
        if not self._listas_validas(info):
            return None, 400

        novo_nome = info.get("nome", medicamento.nome)
        nova_dosagem = info.get("dosagem", medicamento.dosagem)
        if not novo_nome or not nova_dosagem:
            return None, 400
        medicamento = medicamento_repository.atualizar(
            medicamento, info, self.CAMPOS_EDITAVEIS
        )
        return (medicamento, 200) if medicamento else (None, 500)

    def deletar(self, medicamento_id):
        """Remove um medicamento existente; rollback preserva a sessao se falhar."""
        medicamento, status = self.buscar(medicamento_id)
        if status != 200:
            return None, status
        return (
            (None, 204)
            if medicamento_repository.deletar(medicamento)
            else (None, 500)
        )

    @staticmethod
    def _quantidade_valida(quantidade):
        """Aceita estoque inteiro maior ou igual a zero; bool nao conta como inteiro."""
        return isinstance(quantidade, int) and not isinstance(quantidade, bool) and quantidade >= 0

    @staticmethod
    def _listas_validas(info):
        return all(
            campo not in info
            or (
                isinstance(info[campo], list)
                and all(isinstance(item, str) for item in info[campo])
            )
            for campo in ("horarios", "alertas")
        )
