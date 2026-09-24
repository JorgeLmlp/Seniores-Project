from flask import Blueprint
from controllers.relacionamento.relacionamento_controller import (
    vincular_cuidador_responsavel,
    vincular_paciente_cuidador,
    vincular_responsavel,
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
