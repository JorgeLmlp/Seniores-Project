from .registrar import registrar_bp
from .home import main
from .usuarios import usuarios

blueprints = [
        registrar_bp, 
        usuarios,
        main
    ]

__all__ = ["blueprints"]
