from functools import wraps
from flask import current_app, request, g, jsonify
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from repositories.usuario_repository import classe_por_tipo, buscar_por_id


def emitir_token(usuario):
    return URLSafeTimedSerializer(current_app.config['SECRET_KEY']).dumps(
        {'id': usuario.id, 'tipo': usuario.tipo}, salt='seniores-session')


def autenticado(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        token = request.headers.get('Authorization', '').removeprefix('Bearer ')
        try:
            dados = URLSafeTimedSerializer(current_app.config['SECRET_KEY']).loads(
                token, salt='seniores-session', max_age=86400)
            classe = classe_por_tipo(dados['tipo'])
            g.usuario = buscar_por_id(classe, dados['id']) if classe else None
            if not g.usuario:
                raise BadSignature('Usuario inexistente')
        except (BadSignature, SignatureExpired, KeyError, TypeError):
            return jsonify(erro='Sessão expirada. Entre novamente.'), 401
        return func(*args, **kwargs)
    return wrapper
