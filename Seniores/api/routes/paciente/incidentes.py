from flask import Blueprint

from controllers.paciente.incidente_controller import (
    atualizar_incidente,
    buscar_incidente,
    criar_incidente,
    deletar_incidente,
    listar_incidentes,
)


incidentesbp = Blueprint("incidentes", __name__)
incidentesbp.route("/pacientes/<int:paciente_id>/incidentes", methods=["GET"])(listar_incidentes)
incidentesbp.route("/pacientes/<int:paciente_id>/incidentes", methods=["POST"])(criar_incidente)
incidentesbp.route("/incidentes/<int:incidente_id>", methods=["GET"])(buscar_incidente)
incidentesbp.route("/incidentes/<int:incidente_id>", methods=["PUT", "PATCH"])(atualizar_incidente)
incidentesbp.route("/incidentes/<int:incidente_id>", methods=["DELETE"])(deletar_incidente)
