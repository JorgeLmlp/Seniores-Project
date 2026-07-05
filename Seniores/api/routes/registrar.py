from controllers.user_controller import criar_usuario
from flask import Blueprint

registrar_cuidador = Blueprint('registrar', __name__)

registrar_cuidador.route('/registrar_cuidador/', methods=['POST'])(criar_usuario)
