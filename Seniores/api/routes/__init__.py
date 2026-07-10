from .registrar import *
from .usuarios import usuariosbp
from .registrar_relacionamentos import registrar_relacionamento
blueprints = [
        registrarbp, 
        usuariosbp,
        registrar_relacionamento
    ]

__all__ = ["blueprints"]
