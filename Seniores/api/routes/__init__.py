from .usuario.registrar import *
from .usuario.usuarios import usuariosbp
from .usuario.registrar_relacionamentos import registrar_relacionamento
blueprints = [
        registrarbp, 
        usuariosbp,
        registrar_relacionamento
    ]

__all__ = ["blueprints"]
