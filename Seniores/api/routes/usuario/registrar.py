from controllers.user.user_controller import criar_usuario
from flask import Blueprint

registrarbp  = Blueprint('registrar', __name__)

# Atalhos de cadastro. O corpo ainda deve informar `tipo`, pois o controller e generico.
registrarbp.route('/cuidador', methods=['POST'])(criar_usuario)
registrarbp.route('/paciente', methods=['POST'])(criar_usuario)
registrarbp.route('/responsavel', methods=['POST'])(criar_usuario)
