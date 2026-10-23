from flask import Blueprint

from controllers.paciente.higiene_controller import (
    atualizar_higiene,
    buscar_higiene,
    criar_higiene,
    deletar_higiene,
    listar_higienes,
)


higienebp = Blueprint("higiene", __name__)
higienebp.route("/pacientes/<int:paciente_id>/higiene", methods=["GET"])(listar_higienes)
higienebp.route("/pacientes/<int:paciente_id>/higiene", methods=["POST"])(criar_higiene)
higienebp.route("/higiene/<int:higiene_id>", methods=["GET"])(buscar_higiene)
higienebp.route("/higiene/<int:higiene_id>", methods=["PUT", "PATCH"])(atualizar_higiene)
higienebp.route("/higiene/<int:higiene_id>", methods=["DELETE"])(deletar_higiene)
