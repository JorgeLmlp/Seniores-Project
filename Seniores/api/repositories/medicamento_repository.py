from extensions import db
from models.paciente.paciente import Paciente
from models.paciente.remedio import Remedio


def buscar_paciente(paciente_id):
    """Busca o paciente pelo ID usado na URL."""
    return db.session.get(Paciente, paciente_id)


def buscar_medicamento(medicamento_id):
    """Busca um medicamento sem depender do paciente informado pelo cliente."""
    return db.session.get(Remedio, medicamento_id)


def listar_por_paciente(paciente_id):
    """Retorna a lista persistida do paciente, ordenada pelo nome."""
    return db.session.scalars(
        db.select(Remedio)
        .where(Remedio.paciente_id == paciente_id)
        .order_by(Remedio.nome)
    ).all()


def salvar(medicamento):
    """Insere ou atualiza conforme o objeto tenha ou nao um ID."""
    db.session.add(medicamento)
    db.session.commit()
    return medicamento


def remover(medicamento):
    """Exclui o registro e confirma a transacao."""
    db.session.delete(medicamento)
    db.session.commit()
