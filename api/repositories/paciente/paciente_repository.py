"""Consultas compartilhadas pelos recursos clinicos de um paciente."""

from extensions import db
from models.paciente.paciente import Paciente


def buscar_paciente(paciente_id):
    return db.session.get(Paciente, paciente_id)


def buscar_registro(modelo, registro_id):
    return db.session.get(modelo, registro_id)


def listar_registros(modelo, paciente_id):
    consulta = (
        db.select(modelo)
        .where(modelo.paciente_id == paciente_id)
        .order_by(modelo.data_criacao.desc())
    )
    return db.session.scalars(consulta).all()
