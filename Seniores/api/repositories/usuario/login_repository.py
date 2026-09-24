"""Consultas usadas apenas pelo fluxo de autenticacao."""

from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


CLASSES_POR_TIPO = {
    "cuidador": Cuidador,
    "paciente": Paciente,
    "responsavel": Responsavel,
}


def buscar_por_email(email, tipo=None):
    """Busca o usuario no tipo pedido ou em todas as tabelas de usuarios."""
    classes = [CLASSES_POR_TIPO.get((tipo or "").lower())] if tipo else CLASSES_POR_TIPO.values()
    if any(classe is None for classe in classes):
        return None
    for classe in classes:
        usuario = classe.buscar_por_email(email)
        if usuario:
            return usuario
    return None
