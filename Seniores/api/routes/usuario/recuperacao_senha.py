from flask import Blueprint
from controllers.usuario.recuperacao_senha_controller import solicitar, redefinir

recuperacao_senhapb = Blueprint('recuperacao_senha', __name__)
recuperacao_senhapb.add_url_rule('/users/password/solicitar', view_func=solicitar, methods=['POST'])
recuperacao_senhapb.add_url_rule('/users/password/redefinir', view_func=redefinir, methods=['POST'])
