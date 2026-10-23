from flask import Blueprint
from controllers.user.relationship_controller import (
    desvincular_cuidador_paciente,
    desvincular_responsavel_paciente,
    listar_cuidador_paciente,
    listar_responsaveis_paciente,
    vincular_responsavel,
    vincular_paciente_cuidador,
    vincular_cuidador_responsavel,
)

registrar_relacionamento = Blueprint("registrar_relacionamento", __name__)

# O controller recebe cpfPaciente e cpfResponsavel no JSON.
registrar_relacionamento.route(
    "/registrar_relacionamento", methods=["POST"]
)(vincular_responsavel)

registrar_relacionamento.route(
    "/relacionamentos/paciente-cuidador", methods=["POST"]
)(vincular_paciente_cuidador)
registrar_relacionamento.route(
    "/relacionamentos/cuidador-responsavel", methods=["POST"]
)(vincular_cuidador_responsavel)

registrar_relacionamento.route(
    "/pacientes/<int:paciente_id>/cuidador", methods=["GET"]
)(listar_cuidador_paciente)
registrar_relacionamento.route(
    "/pacientes/<int:paciente_id>/cuidador", methods=["DELETE"]
)(desvincular_cuidador_paciente)
registrar_relacionamento.route(
    "/pacientes/<int:paciente_id>/responsaveis", methods=["GET"]
)(listar_responsaveis_paciente)
registrar_relacionamento.route(
    "/pacientes/<int:paciente_id>/responsaveis/<int:responsavel_id>",
    methods=["DELETE"],
)(desvincular_responsavel_paciente)
