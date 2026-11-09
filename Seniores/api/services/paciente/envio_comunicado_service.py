"""Entrega explicitamente solicitada por e-mail, com estados persistidos.

Um comunicado salvo no banco NAO significa mensagem entregue. Sem SMTP,
continuamos com status pendente, sem afirmar envio por WhatsApp/SMS.
"""

import os
import smtplib
import ssl
from email.message import EmailMessage
from datetime import datetime

from models.paciente.registro_app import RegistroApp
from extensions import db


def enviar_comunicado_email(registro_id):
    registro = db.session.get(RegistroApp, registro_id)
    if not registro or registro.recurso != 'comunicados':
        return None, 404
    dados = dict(registro.dados or {})
    status = dados.get('status', 'pendente')
    if status == 'enviando':
        return None, 409
    if status == 'enviado':
        return registro, 200  # Nunca retransmitir automaticamente.

    if int(dados.get('tentativas', 0)) >= 3:
        return None, 429
    destinatarios = dados.get('destinatarios', [])
    if (not isinstance(destinatarios, list) or not destinatarios or len(destinatarios) > 20 or
            any(not isinstance(d, dict) or not isinstance(d.get('email'), str)
                or '@' not in d['email'] for d in destinatarios)):
        return None, 400
    mensagem = dados.get('mensagem')
    if not isinstance(mensagem, str) or not mensagem.strip():
        return None, 400
    if not os.getenv('SMTP_HOST') or not os.getenv('SMTP_FROM'):
        return None, 503

    dados['status'] = 'reenvio' if status == 'falhou' else 'enviando'
    dados['tentativas'] = int(dados.get('tentativas', 0)) + 1
    if not registro.atualizar(dados):
        return None, 500
    dados['status'] = 'enviando'
    if not registro.atualizar(dados):
        return None, 500

    try:
        porta = int(os.getenv('SMTP_PORT', '587'))
        contexto = ssl.create_default_context()
        if porta == 465:
            smtp = smtplib.SMTP_SSL(os.environ['SMTP_HOST'], porta,
                                    timeout=15, context=contexto)
        else:
            smtp = smtplib.SMTP(os.environ['SMTP_HOST'], porta, timeout=15)
        with smtp:
            if porta != 465:
                smtp.starttls(context=contexto)
            if os.getenv('SMTP_USER'):
                smtp.login(os.environ['SMTP_USER'], os.getenv('SMTP_PASSWORD', ''))
            # Mensagens separadas: nao expomos os e-mails dos contatos entre si.
            for destinatario in destinatarios:
                email = EmailMessage()
                email['From'] = os.environ['SMTP_FROM']
                email['To'] = destinatario['email']
                email['Subject'] = 'Comunicado Seniores'
                email.set_content(mensagem.strip())
                smtp.send_message(email)
    except (OSError, ValueError, smtplib.SMTPException):
        dados['status'] = 'falhou'
        dados['erro_envio'] = 'Falha no envio de e-mail. Confira o SMTP e tente novamente.'
        registro.atualizar(dados)
        return registro, 502

    dados['status'] = 'enviado'
    dados.pop('erro_envio', None)
    dados['enviado_em'] = datetime.now().isoformat()
    if not registro.atualizar(dados):
        return None, 500
    return registro, 200
