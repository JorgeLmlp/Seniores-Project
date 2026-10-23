from flask import Blueprint

from controllers.paciente.dieta_controller import (
    atualizar_dieta,
    buscar_dieta,
    criar_dieta,
    deletar_dieta,
    listar_dietas,
)


dietasbp = Blueprint("dietas", __name__)
dietasbp.route("/pacientes/<int:paciente_id>/dietas", methods=["GET"])(listar_dietas)
dietasbp.route("/pacientes/<int:paciente_id>/dietas", methods=["POST"])(criar_dieta)
dietasbp.route("/dietas/<int:dieta_id>", methods=["GET"])(buscar_dieta)
dietasbp.route("/dietas/<int:dieta_id>", methods=["PUT", "PATCH"])(atualizar_dieta)
dietasbp.route("/dietas/<int:dieta_id>", methods=["DELETE"])(deletar_dieta)
