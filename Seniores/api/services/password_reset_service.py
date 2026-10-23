import logging
import os
import smtplib
from email.message import EmailMessage
from secrets import token_urlsafe

from flask import current_app
from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer
from werkzeug.security import generate_password_hash

from extensions import db
from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


logger = logging.getLogger(__name__)
CLASSES_POR_TIPO = {
    "cuidador": Cuidador,
    "paciente": Paciente,
    "responsavel": Responsavel,
}


class PasswordResetService:
    """Gera tokens assinados, temporários e de uso único para troca de senha."""

    TOKEN_MAX_AGE = 15 * 60
    SALT = "seniores-password-reset-v1"

    @classmethod
    def _serializer(cls):
        return URLSafeTimedSerializer(
            current_app.config["SECRET_KEY"], salt=cls.SALT
        )

    @classmethod
    def _usuario_por_email(cls, email):
        for modelo in CLASSES_POR_TIPO.values():
            usuario = modelo.buscar_por_email(email)
            if usuario:
                return usuario
        return None

    @classmethod
    def solicitar(cls, email):
        usuario = cls._usuario_por_email((email or "").strip().lower())
        if not usuario:
            return None

        usuario.senha_reset_nonce = token_urlsafe(32)
        db.session.commit()
        token = cls._serializer().dumps(
            {
                "id": usuario.id,
                "tipo": usuario.tipo,
                "nonce": usuario.senha_reset_nonce,
            }
        )
        cls._enviar_email(usuario.email, token)
        return token

    @classmethod
    def redefinir(cls, token, nova_senha):
        try:
            dados = cls._serializer().loads(token, max_age=cls.TOKEN_MAX_AGE)
        except (BadSignature, SignatureExpired, TypeError):
            return False

        modelo = CLASSES_POR_TIPO.get(dados.get("tipo"))
        if not modelo:
            return False
        usuario = modelo.buscar_por_id(dados.get("id"))
        if not usuario or not usuario.senha_reset_nonce:
            return False
        if usuario.senha_reset_nonce != dados.get("nonce"):
            return False

        usuario.password = generate_password_hash(nova_senha)
        usuario.senha_reset_nonce = None
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return False
        return True

    @classmethod
    def _enviar_email(cls, destinatario, token):
        """Envia o link quando SMTP estiver configurado; nunca falha a resposta pública."""
        host = current_app.config.get("SMTP_HOST")
        if not host:
            logger.warning("SMTP não configurado; e-mail de recuperação não enviado.")
            return

        url_base = current_app.config.get(
            "PASSWORD_RESET_URL", "seniores://redefinir-senha?token="
        )
        link = f"{url_base}{token}"
        mensagem = EmailMessage()
        mensagem["Subject"] = "Recuperação de senha — Seniores"
        mensagem["From"] = current_app.config.get(
            "PASSWORD_RESET_FROM", current_app.config.get("SMTP_USER", "")
        )
        mensagem["To"] = destinatario
        mensagem.set_content(
            "Recebemos uma solicitação para redefinir sua senha.\n\n"
            f"Use este link em até 15 minutos:\n{link}\n\n"
            "Se você não fez esta solicitação, ignore este e-mail."
        )

        port = int(current_app.config.get("SMTP_PORT", 587))
        usuario = current_app.config.get("SMTP_USER")
        senha = current_app.config.get("SMTP_PASSWORD")
        try:
            with smtplib.SMTP(host, port, timeout=10) as servidor:
                servidor.starttls()
                if usuario and senha:
                    servidor.login(usuario, senha)
                servidor.send_message(mensagem)
        except Exception:
            logger.exception("Falha ao enviar e-mail de recuperação.")


def token_exposto_apenas_em_desenvolvimento(token):
    """Permite testar sem SMTP somente quando explicitamente habilitado."""
    return token if os.getenv("PASSWORD_RESET_EXPOSE_TOKEN") == "1" else None
