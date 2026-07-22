"""Reune os blueprints que a aplicacao registra ao iniciar."""

from .usuario.registrar import *
from .usuario.usuarios import usuariosbp
from .usuario.registrar_relacionamentos import registrar_relacionamento
from .medicamento.medicamento import medicamentobp
blueprints = [
        # A ordem nao altera as URLs; ela apenas organiza os grupos de rotas.
        registrarbp, 
        usuariosbp,
        registrar_relacionamento,
        medicamentobp,
    ]

__all__ = ["blueprints"]
