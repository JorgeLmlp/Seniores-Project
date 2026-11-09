"""Consultas de medicamentos; nenhuma funcao desta camada altera dados."""

from extensions import db
from models.medicamento.remedio import Remedio


def buscar_por_id(medicamento_id):
    """Busca um medicamento pela chave primaria."""
    return db.session.get(Remedio, medicamento_id)


def listar_por_paciente(paciente_id):
    """Lista alfabeticamente os medicamentos vinculados ao paciente."""
    return db.session.scalars(
        db.select(Remedio)
        .where(Remedio.paciente_id == paciente_id)
        .order_by(Remedio.nome)
    ).all()
