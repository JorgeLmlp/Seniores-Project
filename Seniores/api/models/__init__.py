"""Importa os models para que o SQLAlchemy registre todas as tabelas."""

from .cuidador import *
from .medicamento import *
from .paciente import *
from .relacionamento import *
from .responsavel import *

__all__ = ["Cuidador", "Remedio", "Paciente", "SinalVital", "Paciente_responsavel", "Responsavel"]
