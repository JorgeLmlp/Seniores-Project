from flask import Blueprint

from controllers.paciente.gasto_controller import (
    atualizar_gasto,
    buscar_gasto,
    criar_gasto,
    deletar_gasto,
    listar_gastos,
)


gastosbp = Blueprint("gastos", __name__)
gastosbp.route("/pacientes/<int:paciente_id>/gastos", methods=["GET"])(listar_gastos)
gastosbp.route("/pacientes/<int:paciente_id>/gastos", methods=["POST"])(criar_gasto)
gastosbp.route("/gastos/<int:gasto_id>", methods=["GET"])(buscar_gasto)
gastosbp.route("/gastos/<int:gasto_id>", methods=["PUT", "PATCH"])(atualizar_gasto)
gastosbp.route("/gastos/<int:gasto_id>", methods=["DELETE"])(deletar_gasto)
