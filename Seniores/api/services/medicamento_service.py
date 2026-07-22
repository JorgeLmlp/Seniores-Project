from extensions import db
from models.paciente.remedio import Remedio
from repositories import medicamento_repository


class MedicamentoService:
    """Regras para manter a lista de medicamentos de cada paciente."""

    # Apenas estes campos podem ser alterados depois do cadastro.
    CAMPOS_EDITAVEIS = {
        "nome", "descricao", "dosagem", "fabricante", "lote", "quantidade"
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

        medicamento = Remedio(
            paciente_id=paciente.id,
            nome=nome,
            descricao=info.get("descricao"),
            dosagem=dosagem,
            fabricante=info.get("fabricante"),
            lote=info.get("lote"),
            quantidade=quantidade,
        )
        return self._salvar(medicamento, 201)

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

        for campo in self.CAMPOS_EDITAVEIS:
            if campo in info:
                setattr(medicamento, campo, info[campo])

        if not medicamento.nome or not medicamento.dosagem:
            return None, 400
        return self._salvar(medicamento, 200)

    def deletar(self, medicamento_id):
        """Remove um medicamento existente; rollback preserva a sessao se falhar."""
        medicamento, status = self.buscar(medicamento_id)
        if status != 200:
            return None, status
        try:
            medicamento_repository.remover(medicamento)
        except Exception:
            db.session.rollback()
            return None, 500
        return None, 204

    @staticmethod
    def _quantidade_valida(quantidade):
        """Aceita estoque inteiro maior ou igual a zero; bool nao conta como inteiro."""
        return isinstance(quantidade, int) and not isinstance(quantidade, bool) and quantidade >= 0

    @staticmethod
    def _salvar(medicamento, status):
        """Confirma insert/update e transforma falha do banco em status 500."""
        try:
            medicamento_repository.salvar(medicamento)
        except Exception:
            db.session.rollback()
            return None, 500
        return medicamento, status
