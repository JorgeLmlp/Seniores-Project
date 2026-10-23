from flask import Blueprint

from controllers.paciente.consulta_controller import (
    atualizar_consulta,
    buscar_consulta,
    criar_consulta,
    deletar_consulta,
    listar_consultas,
)


consultasbp = Blueprint("consultas", __name__)
consultasbp.route("/pacientes/<int:paciente_id>/consultas", methods=["GET"])(listar_consultas)
consultasbp.route("/pacientes/<int:paciente_id>/consultas", methods=["POST"])(criar_consulta)
consultasbp.route("/consultas/<int:consulta_id>", methods=["GET"])(buscar_consulta)
consultasbp.route("/consultas/<int:consulta_id>", methods=["PUT", "PATCH"])(atualizar_consulta)
consultasbp.route("/consultas/<int:consulta_id>", methods=["DELETE"])(deletar_consulta)
