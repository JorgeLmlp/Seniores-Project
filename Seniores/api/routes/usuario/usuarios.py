from flask import Blueprint
from controllers.usuario.usuario_controller import (
    atualizar_usuario,
    buscar_usuario,
    criar_usuario,
    deletar_usuario,
    listar_usuarios,
    login,
)


usuariosbp = Blueprint('users', __name__)
# Rotas gerais: `tipo` seleciona a tabela correta nos endpoints por ID.
usuariosbp.route('/users/', methods=['POST'])(criar_usuario)
usuariosbp.route('/users/', methods=['GET'])(listar_usuarios)
usuariosbp.route('/users/<tipo>/<int:usuario_id>/', methods=['GET'])(buscar_usuario)
usuariosbp.route('/users/<tipo>/<int:usuario_id>/', methods=['PUT', 'PATCH'])(atualizar_usuario)
usuariosbp.route('/users/<tipo>/<int:usuario_id>/', methods=['DELETE'])(deletar_usuario)
# Credenciais seguem no corpo JSON; usar POST evita expo-las na URL.
usuariosbp.route('/users/login/', methods=['POST'])(login)
