from flask import Blueprint

from controllers.paciente.emergencia_controller import (
    atualizar_contato,
    buscar_contato,
    criar_alerta,
    criar_contato,
    deletar_contato,
    listar_alertas,
    listar_contatos,
    resolver_alerta,
)


emergenciabp = Blueprint("emergencia", __name__)
emergenciabp.route("/pacientes/<int:paciente_id>/contatos-emergencia", methods=["GET"])(listar_contatos)
emergenciabp.route("/pacientes/<int:paciente_id>/contatos-emergencia", methods=["POST"])(criar_contato)
emergenciabp.route("/contatos-emergencia/<int:contato_id>", methods=["GET"])(buscar_contato)
emergenciabp.route("/contatos-emergencia/<int:contato_id>", methods=["PUT", "PATCH"])(atualizar_contato)
emergenciabp.route("/contatos-emergencia/<int:contato_id>", methods=["DELETE"])(deletar_contato)
emergenciabp.route("/pacientes/<int:paciente_id>/alertas-emergencia", methods=["GET"])(listar_alertas)
emergenciabp.route("/pacientes/<int:paciente_id>/alertas-emergencia", methods=["POST"])(criar_alerta)
emergenciabp.route("/alertas-emergencia/<int:alerta_id>/resolver", methods=["PATCH"])(resolver_alerta)
