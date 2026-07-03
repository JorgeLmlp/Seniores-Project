from .registrar import registrar_cuidador
from .home import main

blueprints = [
        registrar_cuidador, 
        main
    ]

__all__ = ["blueprints"]