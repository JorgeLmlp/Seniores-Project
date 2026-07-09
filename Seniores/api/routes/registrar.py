from controllers.user_controller import criar_usuario
from flask import Blueprint

registrar_bp  = Blueprint('registrar', __name__)


registrar_bp.route('/cuidador/', methods=['POST'])(criar_usuario)
registrar_bp.route('/paciente/', methods=['POST'])(criar_usuario)
registrar_bp.route('/familiar/', methods=['POST'])(criar_usuario)
