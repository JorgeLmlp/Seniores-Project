"""Consultas compartilhadas pelos recursos clinicos de um paciente."""

from models.paciente.paciente import Paciente


def buscar_paciente(paciente_id):
    return Paciente.buscar_por_id(paciente_id)


def buscar_registro(modelo, registro_id):
    return modelo.buscar_por_id(registro_id)


def listar_registros(modelo, paciente_id):
    return modelo.listar_por_paciente(paciente_id)
