from flask import jsonify, request
from services.usuario.usuario_service import UsuarioService


usuario_service = UsuarioService()


def _usuario_json(usuario):
    """Converte o model para resposta sem expor a senha."""
    return usuario.to_dict


def criar_usuario():
    """Recebe o JSON de cadastro e converte os status do service em HTTP."""
    info = request.get_json(silent=True) or {}
    usuario, status = usuario_service.criar(info)

    if status == 400:
        return jsonify({'erro': 'Dados obrigatorios ausentes ou tipo invalido'}), 400
    if status == 409:
        return jsonify({'erro': 'Usuario ja cadastrado com este email ou CPF'}), 409
    if status == 500:
        return jsonify({'erro': 'Nao foi possivel salvar o usuario'}), 500

    return jsonify(_usuario_json(usuario)), 201


def listar_usuarios():
    """Lista usuarios e permite filtrar pacientes pelo cuidador vinculado."""
    tipo = request.args.get('tipo')
    cuidador_id = request.args.get('cuidador_id')
    usuarios, status = usuario_service.listar(tipo, cuidador_id)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario ou cuidador_id invalido'}), 400

    return jsonify([_usuario_json(usuario) for usuario in usuarios]), 200


def buscar_usuario(tipo, usuario_id):
    """Busca um usuario pela combinacao de tipo e ID presente na rota."""
    usuario, status = usuario_service.buscar_por_id(tipo, usuario_id)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400
    if status == 404:
        return jsonify({'erro': 'Usuario nao encontrado'}), 404

    return jsonify(_usuario_json(usuario)), 200


def login():
    """Autentica um usuario sem retornar nem comparar senha em texto puro."""
    usuario, status = usuario_service.login(request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({'erro': 'Email e senha sao obrigatorios; tipo deve ser valido'}), 400
    if status == 401:
        return jsonify({'erro': 'Email ou senha invalidos'}), 401
    return jsonify(_usuario_json(usuario)), 200


def atualizar_usuario(tipo, usuario_id):
    """Encaminha atualizacao parcial ou completa para o service."""
    info = request.get_json() or {}
    usuario, status = usuario_service.atualizar(tipo, usuario_id, info)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400
    if status == 404:
        return jsonify({'erro': 'Usuario nao encontrado'}), 404
    if status == 409:
        return jsonify({'erro': 'Usuario ja cadastrado com este email ou CPF'}), 409
    if status == 500:
        return jsonify({'erro': 'Nao foi possivel atualizar o usuario'}), 500

    return jsonify(_usuario_json(usuario)), 200


def deletar_usuario(tipo, usuario_id):
    """Exclui e retorna 204, resposta HTTP sem corpo."""
    _, status = usuario_service.deletar(tipo, usuario_id)

    if status == 400:
        return jsonify({'erro': 'Tipo de usuario invalido'}), 400
    if status == 404:
        return jsonify({'erro': 'Usuario nao encontrado'}), 404
    if status == 500:
        return jsonify({'erro': 'Nao foi possivel remover o usuario'}), 500

    return '', 204
