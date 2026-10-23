from flask import Blueprint

from controllers.paciente.notificacao_controller import (
    listar_notificacoes,
    marcar_lida,
    marcar_nao_lida,
)


notificacoesbp = Blueprint("notificacoes", __name__)
notificacoesbp.route("/pacientes/<int:paciente_id>/notificacoes", methods=["GET"])(listar_notificacoes)
notificacoesbp.route("/notificacoes/<int:notificacao_id>/ler", methods=["PATCH"])(marcar_lida)
notificacoesbp.route("/notificacoes/<int:notificacao_id>/nao-ler", methods=["PATCH"])(marcar_nao_lida)
