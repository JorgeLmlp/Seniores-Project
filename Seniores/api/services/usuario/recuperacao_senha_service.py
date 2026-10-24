"""Recuperacao de senha sem novas tabelas: token assinado, curto e de uso unico.

A assinatura inclui uma impressao do hash atual. Ao trocar a senha, todos os
links anteriores tornam-se invalidos. Nunca devolvemos o token pela API.
"""

import hashlib
import hmac
import os
import smtplib
import ssl
from email.message import EmailMessage
from time import monotonic

from flask import current_app
from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer
from werkzeug.security import generate_password_hash

from extensions import db
from repositories import usuario_repository
from services.usuario.usuario_service import CLASSES_POR_TIPO


# Limitacao leve por processo. Em producao, aplicar rate limiting global no proxy.
_tentativas = {}


def _assinador():
    return URLSafeTimedSerializer(current_app.config['SECRET_KEY'],
                                 salt='seniores-redefinicao-de-senha-v1')


def _impressao(usuario):
    return hashlib.sha256(usuario.password.encode('utf-8')).hexdigest()


def _buscar_email(email):
    for classe in CLASSES_POR_TIPO.values():
        usuario = usuario_repository.buscar_por_email(classe, email)
        if usuario:
            return usuario
    return None


def _limitar(email):
    agora = monotonic()
    tentativas = [t for t in _tentativas.get(email, []) if agora-t < 900]
    if len(tentativas) >= 3:
        _tentativas[email] = tentativas
        return False
    tentativas.append(agora)
    _tentativas[email] = tentativas
    # Evita acumulacao ilimitada de enderecos em memoria.
    if len(_tentativas) > 2000:
        _tentativas.clear()
    return True


def _smtp_configurado():
    return bool(os.getenv('SMTP_HOST') and os.getenv('SMTP_FROM'))


def solicitar_recuperacao(email):
    """Retorna (sucesso, status). Resposta publica nunca identifica contas."""
    if not isinstance(email, str) or len(email) > 254 or '@' not in email:
        return False, 400
    email = email.strip().lower()
    if not _smtp_configurado():
        return False, 503
    if not _limitar(email):
        return False, 429
    usuario = _buscar_email(email)
    if not usuario:
        return True, 200

    token = _assinador().dumps({
        'id': usuario.id, 'tipo': usuario.tipo, 'hash': _impressao(usuario)
    })
    mensagem = EmailMessage()
    mensagem['Subject'] = 'Seniores - redefinicao de senha'
    mensagem['From'] = os.getenv('SMTP_FROM')
    mensagem['To'] = usuario.email
    mensagem.set_content(
        'Recebemos uma solicitacao para redefinir sua senha do Seniores.\n\n'
        'No aplicativo, abra "Esqueceu sua senha?" e informe este codigo:\n\n'
        f'{token}\n\n'
        'O codigo expira em 30 minutos e so pode ser usado uma vez.\n'
        'Se voce nao solicitou a alteracao, ignore esta mensagem.\n'
        'Nao encaminhe este codigo para outras pessoas.'
    )
    try:
        porta = int(os.getenv('SMTP_PORT', '587'))
        if not 1 <= porta <= 65535:
            return False, 503
        contexto = ssl.create_default_context()
        if porta == 465:
            with smtplib.SMTP_SSL(os.environ['SMTP_HOST'], porta, timeout=12, context=contexto) as smtp:
                if os.getenv('SMTP_USER'):
                    smtp.login(os.environ['SMTP_USER'], os.getenv('SMTP_PASSWORD', ''))
                smtp.send_message(mensagem)
        else:
            with smtplib.SMTP(os.environ['SMTP_HOST'], porta, timeout=12) as smtp:
                smtp.starttls(context=contexto)
                if os.getenv('SMTP_USER'):
                    smtp.login(os.environ['SMTP_USER'], os.getenv('SMTP_PASSWORD', ''))
                smtp.send_message(mensagem)
    except (OSError, ValueError, smtplib.SMTPException):
        current_app.logger.warning('Falha de SMTP no pedido de redefinicao de senha.')
        # Resposta indistinguivel para contas existentes e inexistentes.
        return True, 200
    return True, 200


def redefinir_senha(token, nova_senha):
    if not isinstance(token, str) or len(token) > 2048:
        return False, 400
    if not isinstance(nova_senha, str) or not 8 <= len(nova_senha) <= 128:
        return False, 400
    try:
        dados = _assinador().loads(token, max_age=30 * 60)
        tipo, usuario_id, hash_original = dados['tipo'], int(dados['id']), dados['hash']
        classe = CLASSES_POR_TIPO.get(tipo)
        if not classe or usuario_id < 1 or not isinstance(hash_original, str):
            return False, 400
        usuario = db.session.get(classe, usuario_id)
        if not usuario or not hmac.compare_digest(hash_original, _impressao(usuario)):
            return False, 400
    except (BadSignature, SignatureExpired, ValueError, TypeError, KeyError):
        return False, 400
    usuario.password = generate_password_hash(nova_senha)
    try:
        db.session.commit()
        return True, 200
    except Exception:
        db.session.rollback()
        return False, 500
