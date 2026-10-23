"""Importa os models para que o SQLAlchemy registre todas as tabelas."""

from .cuidador import *
from .paciente import *
from .relacionamento import *
from .responsavel import *

__all__ = [
    "Cuidador", "Remedio", "Paciente", "Consulta", "Exame", "ItemEstoque", "Incidente",
    "ContatoEmergencia", "AlertaEmergencia",
    "RegistroDiario",
    "Gasto",
    "Notificacao", "Comunicado", "DocumentoExame", "AdministracaoMedicamento", "Higiene", "Lesao", "Dieta",
    "Paciente_responsavel", "Responsavel",
]
