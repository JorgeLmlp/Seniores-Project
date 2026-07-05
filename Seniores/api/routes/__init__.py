from .registrar import registrar_cuidador
from .home import main
from .usuarios import usuarios

blueprints = [
        registrar_cuidador, 
        usuarios,
        main
    ]

__all__ = ["blueprints"]
