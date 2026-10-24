"""Endpoints publicos para solicitar e concluir a redefinicao de senha."""
from flask import Blueprint, jsonify, request

from services.usuario.recuperacao_senha_service import (
    solicitar_recuperacao, redefinir_senha,
)

recuperacao_senhapb = Blueprint('recuperacao_senha', __name__)


@recuperacao_senhapb.post('/users/password/solicitar')
def solicitar():
    dados = request.get_json(silent=True) or {}
    enviado, status = solicitar_recuperacao(dados.get('email'))
    if status == 400:
        return jsonify({'erro': 'Informe um e-mail valido.'}), 400
    if status == 429:
        return jsonify({'erro': 'Muitas solicitacoes. Tente novamente mais tarde.'}), 429
    if status == 503:
        return jsonify({'erro': 'Recuperacao de senha indisponivel: SMTP nao configurado.'}), 503
    if status == 502:
        return jsonify({'erro': 'Nao foi possivel processar o envio. Tente novamente.'}), 502
    return jsonify({'mensagem': 'Se houver uma conta vinculada a esse e-mail, enviaremos um codigo.'}), 200


@recuperacao_senhapb.post('/users/password/redefinir')
def redefinir():
    dados = request.get_json(silent=True) or {}
    alterado, status = redefinir_senha(dados.get('token'), dados.get('nova_senha'))
    if status == 400:
        return jsonify({'erro': 'Codigo invalido/expirado ou senha menor que 8 caracteres.'}), 400
    if status != 200:
        return jsonify({'erro': 'Nao foi possivel redefinir a senha.'}), 500
    return jsonify({'mensagem': 'Senha redefinida. Entre novamente.'}), 200
