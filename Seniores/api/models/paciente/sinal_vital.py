"""Compatibilidade para imports antigos de SinalVital.

O model vive em ``paciente.py`` para manter a relacao com Paciente em um unico
local e evitar duas classes mapeando a mesma tabela SQLAlchemy.
"""

from .paciente import SinalVital

__all__ = ["SinalVital"]
