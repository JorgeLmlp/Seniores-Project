"""Operações de escrita compartilhadas por fluxos que alteram vários models."""
from extensions import db


def adicionar(registro):
    db.session.add(registro)


def remover(registro):
    db.session.delete(registro)


def confirmar():
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        raise


def cancelar():
    db.session.rollback()
