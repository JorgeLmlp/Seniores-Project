from flask import Blueprint
from controllers.user_controller import (
    atualizar_usuario,
    buscar_usuario,
    criar_usuario,
    deletar_usuario,
    listar_usuarios,
)


usuariosbp = Blueprint('users', __name__)
usuariosbp.route('/users/', methods=['POST'])(criar_usuario)
usuariosbp.route('/users/', methods=['GET'])(listar_usuarios)
usuariosbp.route('/users/<tipo>/<int:usuario_id>/', methods=['GET'])(buscar_usuario)
usuariosbp.route('/users/<tipo>/<int:usuario_id>/', methods=['PUT', 'PATCH'])(atualizar_usuario)
usuariosbp.route('/users/<tipo>/<int:usuario_id>/', methods=['DELETE'])(deletar_usuario)
usuariosbp.route('/users/login/', methods=['GET'])(buscar_usuario)