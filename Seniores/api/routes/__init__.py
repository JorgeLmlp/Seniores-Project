from .registrar import *
from .usuarios import usuariosbp
from registrar_relacionamentos import registrar_relacionamento
blueprints = [
        registrarbp, 
        registrar_relacionamento,
        usuariosbp,
    ]

__all__ = ["blueprints"]
