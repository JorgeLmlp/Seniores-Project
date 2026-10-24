from models.medicamento.remedio import Remedio
from repositories import medicamento_repository, paciente_repository


class MedicamentoService:
    """Regras para manter a lista de medicamentos de cada paciente."""

    # Apenas estes campos podem ser alterados depois do cadastro.
    CAMPOS_EDITAVEIS = {
        "nome", "descricao", "dosagem", "fabricante", "lote", "quantidade",
        "frequencia", "horarios", "alertas",
        "alerta_sonoro", "som_alerta",
    }

    def criar(self, paciente_id, info):
        """Cria o medicamento somente se o paciente da URL existir."""
        paciente = paciente_repository.buscar_paciente(paciente_id)
        if not paciente:
            return None, 404

        nome = info.get("nome")
        dosagem = info.get("dosagem")
        frequencia = info.get("frequencia")
        if not nome or not dosagem or not isinstance(frequencia, str) or not frequencia.strip():
            return None, 400

        quantidade = info.get("quantidade")
        if quantidade is not None and not self._quantidade_valida(quantidade):
            return None, 400
        if not self._listas_validas(info):
            return None, 400
        if "alerta_sonoro" in info and not isinstance(info["alerta_sonoro"], bool):
            return None, 400
        medicamento = Remedio.criar(paciente.id, info)
        return (medicamento, 201) if medicamento else (None, 500)

    def listar(self, paciente_id):
        """Impede que uma lista vazia esconda um ID de paciente inexistente."""
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        return medicamento_repository.listar_por_paciente(paciente_id), 200

    def buscar(self, medicamento_id):
        """Busca pelo identificador unico do medicamento."""
        medicamento = medicamento_repository.buscar_por_id(medicamento_id)
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
        if "alerta_sonoro" in info and not isinstance(info["alerta_sonoro"], bool):
            return None, 400
        if "frequencia" in info and (
            not isinstance(info["frequencia"], str) or not info["frequencia"].strip()
        ):
            return None, 400

        novo_nome = info.get("nome", medicamento.nome)
        nova_dosagem = info.get("dosagem", medicamento.dosagem)
        nova_frequencia = info.get("frequencia", medicamento.frequencia)
        if not novo_nome or not nova_dosagem or not nova_frequencia:
            return None, 400
        medicamento = medicamento.atualizar(info, self.CAMPOS_EDITAVEIS)
        return (medicamento, 200) if medicamento else (None, 500)

    def deletar(self, medicamento_id):
        """Remove medication and the stored picture atomically."""
        medicamento, status = self.buscar(medicamento_id)
        if status != 200:
            return None, status
        from extensions import db
        from models.paciente.registro_app import RegistroApp
        foto = db.session.scalar(db.select(RegistroApp).where(
            RegistroApp.paciente_id == medicamento.paciente_id,
            RegistroApp.recurso == f'medfoto:{medicamento.id}',
        ).limit(1))
        try:
            if foto:
                db.session.delete(foto)
            db.session.delete(medicamento)
            db.session.commit()
            return None, 204
        except Exception:
            db.session.rollback()
            return None, 500

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
