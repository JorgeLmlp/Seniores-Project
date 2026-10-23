from flask import Blueprint

from controllers.paciente.relatorio_controller import enviar_historico_email


relatoriobp = Blueprint("relatorio", __name__)
relatoriobp.route("/historico/email", methods=["POST"])(enviar_historico_email)
