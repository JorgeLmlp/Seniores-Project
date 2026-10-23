from flask import Blueprint

from controllers.paciente.comunicado_controller import (
    atualizar_comunicado,
    criar_comunicado,
    deletar_comunicado,
    listar_comunicados,
    reenviar_comunicado,
)


comunicadosbp = Blueprint("comunicados", __name__)
comunicadosbp.route(
    "/pacientes/<int:paciente_id>/comunicados", methods=["GET"]
)(listar_comunicados)
comunicadosbp.route(
    "/pacientes/<int:paciente_id>/comunicados", methods=["POST"]
)(criar_comunicado)
comunicadosbp.route(
    "/pacientes/<int:paciente_id>/comunicados/<int:comunicado_id>",
    methods=["PATCH", "PUT"],
)(atualizar_comunicado)
comunicadosbp.route(
    "/pacientes/<int:paciente_id>/comunicados/<int:comunicado_id>",
    methods=["DELETE"],
)(deletar_comunicado)
comunicadosbp.route(
    "/pacientes/<int:paciente_id>/comunicados/<int:comunicado_id>/reenviar",
    methods=["POST"],
)(reenviar_comunicado)
