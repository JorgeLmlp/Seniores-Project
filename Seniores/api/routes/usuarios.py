from flask import Blueprint
from controllers.user_controller import (
    atualizar_usuario,
    buscar_usuario,
    criar_usuario,
    deletar_usuario,
    listar_usuarios,
)


usuarios = Blueprint('users', __name__)
usuarios.route('/users/', methods=['POST'])(criar_usuario)
usuarios.route('/users/', methods=['GET'])(listar_usuarios)
usuarios.route('/users/<tipo>/<int:usuario_id>/', methods=['GET'])(buscar_usuario)
usuarios.route('/users/<tipo>/<int:usuario_id>/', methods=['PUT', 'PATCH'])(atualizar_usuario)
usuarios.route('/users/<tipo>/<int:usuario_id>/', methods=['DELETE'])(deletar_usuario)
