"""Consultas compartilhadas pelos services relacionados ao paciente."""

from extensions import db
from models.paciente.paciente import Paciente, SinalVital
from models.paciente.registro_app import RegistroApp


def buscar_paciente(paciente_id):
    """Busca o paciente sem expor SQLAlchemy ao service."""
    return db.session.get(Paciente, paciente_id)


def buscar_registro(modelo, registro_id):
    """Busca por ID qualquer model de registro previamente selecionado."""
    return db.session.get(modelo, registro_id)


def listar_registros(modelo, paciente_id):
    """Lista registros do paciente do mais recente para o mais antigo."""
    return db.session.scalars(
        db.select(modelo)
        .where(modelo.paciente_id == paciente_id)
        .order_by(modelo.data_criacao.desc())
    ).all()


def listar_sinais_vitais(paciente_id):
    """Lista medicoes em ordem cronologica decrescente."""
    return db.session.scalars(
        db.select(SinalVital)
        .where(SinalVital.paciente_id == paciente_id)
        .order_by(SinalVital.data.desc())
    ).all()


def listar_registros_app(paciente_id, recurso):
    """Filtra a tabela flexivel pelo paciente e pelo tipo de recurso."""
    return db.session.scalars(
        db.select(RegistroApp)
        .where(RegistroApp.paciente_id == paciente_id, RegistroApp.recurso == recurso)
        .order_by(RegistroApp.data_criacao.desc())
    ).all()


def buscar_registro_app(registro_id):
    """Busca um registro flexivel pela chave primaria."""
    return db.session.get(RegistroApp, registro_id)
