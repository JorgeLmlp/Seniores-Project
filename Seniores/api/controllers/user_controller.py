from flask import jsonify, request
from services.user_services import UserService


user_service = UserService()


def _usuario_json(usuario):
    return usuario.to_dict


def criar_usuario():
    info = request.get_json(silent=True) or {}
    usuario, status = user_service.criar(info)

    if status == 400:
        return jsonify({'erro': 'Dados obrigatorios ausentes ou tipo invalido'}), 400
    if status == 409:
        return jsonify({'erro': 'Usuario ja cadastrado com este email ou CPF'}), 409

    return jsonify(_usuario_json(usuario)), 201


def listar_usuarios():
    tipo = request.args.get('tipo')
    usuarios, status = user_service.listar(tipo)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400

    return jsonify([_usuario_json(usuario) for usuario in usuarios]), 200


def buscar_usuario(tipo, usuario_id):
    usuario, status = user_service.buscar_por_id(tipo, usuario_id)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400
    if status == 404:
        return jsonify({'erro': 'Usuario nao encontrado'}), 404

    return jsonify(_usuario_json(usuario)), 200


def atualizar_usuario(tipo, usuario_id):
    info = request.get_json(silent=True) or {}
    usuario, status = user_service.atualizar(tipo, usuario_id, info)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400
    if status == 404:
        return jsonify({'erro': 'Usuario nao encontrado'}), 404
    if status == 409:
        return jsonify({'erro': 'Usuario ja cadastrado com este email ou CPF'}), 409

    return jsonify(_usuario_json(usuario)), 200


def deletar_usuario(tipo, usuario_id):
    _, status = user_service.deletar(tipo, usuario_id)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400
    if status == 404:
        return jsonify({'erro': 'Usuario nao encontrado'}), 404

    return '', 204
