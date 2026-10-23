from flask import Blueprint

from controllers.paciente.estoque_controller import (
    atualizar_item,
    buscar_item,
    criar_item,
    deletar_item,
    listar_estoque,
)


estoquebp = Blueprint("estoque", __name__)
estoquebp.route("/pacientes/<int:paciente_id>/estoque", methods=["GET"])(listar_estoque)
estoquebp.route("/pacientes/<int:paciente_id>/estoque", methods=["POST"])(criar_item)
estoquebp.route("/estoque/<int:item_id>", methods=["GET"])(buscar_item)
estoquebp.route("/estoque/<int:item_id>", methods=["PUT", "PATCH"])(atualizar_item)
estoquebp.route("/estoque/<int:item_id>", methods=["DELETE"])(deletar_item)
