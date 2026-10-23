from flask import jsonify, request

from services.password_reset_service import (
    PasswordResetService,
    token_exposto_apenas_em_desenvolvimento,
)


def solicitar_recuperacao_senha():
    dados = request.get_json(silent=True) or {}
    email = (dados.get("email") or "").strip().lower()
    if not email:
        return jsonify({"erro": "E-mail é obrigatório"}), 400

    token = PasswordResetService.solicitar(email)
    resposta = {
        "mensagem": "Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação."
    }
    token_local = token_exposto_apenas_em_desenvolvimento(token)
    if token_local:
        resposta["token_desenvolvimento"] = token_local
    return jsonify(resposta), 200


def redefinir_senha():
    dados = request.get_json(silent=True) or {}
    token = dados.get("token")
    nova_senha = dados.get("nova_senha") or dados.get("senha")
    if not token or not nova_senha or len(nova_senha) < 6:
        return jsonify(
            {"erro": "Token e senha com pelo menos 6 caracteres são obrigatórios"}
        ), 400
    if not PasswordResetService.redefinir(token, nova_senha):
        return jsonify({"erro": "Token inválido ou expirado"}), 400
    return jsonify({"mensagem": "Senha redefinida com sucesso"}), 200
