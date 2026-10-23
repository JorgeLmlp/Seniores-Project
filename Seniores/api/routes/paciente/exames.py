from flask import Blueprint

from controllers.paciente.exame_controller import (
    atualizar_exame,
    buscar_exame,
    criar_exame,
    deletar_exame,
    listar_exames,
)


examesbp = Blueprint("exames", __name__)
examesbp.route("/pacientes/<int:paciente_id>/exames", methods=["GET"])(listar_exames)
examesbp.route("/pacientes/<int:paciente_id>/exames", methods=["POST"])(criar_exame)
examesbp.route("/exames/<int:exame_id>", methods=["GET"])(buscar_exame)
examesbp.route("/exames/<int:exame_id>", methods=["PUT", "PATCH"])(atualizar_exame)
examesbp.route("/exames/<int:exame_id>", methods=["DELETE"])(deletar_exame)
