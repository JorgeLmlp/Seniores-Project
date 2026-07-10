from .registrar import *
from .home import main
from .usuarios import usuariosbp

blueprints = [
        registrarbp, 
        usuariosbp,
        main
    ]

__all__ = ["blueprints"]
