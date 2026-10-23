from flask import Blueprint

from controllers.paciente.registro_diario_controller import (
    atualizar_registro,
    buscar_registro,
    criar_registro,
    deletar_registro,
    listar_registros,
)


diariobp = Blueprint("diario", __name__)
diariobp.route("/pacientes/<int:paciente_id>/diario", methods=["GET"])(listar_registros)
diariobp.route("/pacientes/<int:paciente_id>/diario", methods=["POST"])(criar_registro)
diariobp.route("/diario/<int:registro_id>", methods=["GET"])(buscar_registro)
diariobp.route("/diario/<int:registro_id>", methods=["PUT", "PATCH"])(atualizar_registro)
diariobp.route("/diario/<int:registro_id>", methods=["DELETE"])(deletar_registro)
