import re
import smtplib
from email.message import EmailMessage

from flask import current_app

from models.paciente.paciente import Paciente
from models.paciente.registro_diario import RegistroDiario


EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class RelatorioService:
    def enviar_por_email(self, paciente_id, email):
        if not Paciente.buscar_por_id(paciente_id):
            return {"erro": "Paciente não encontrado"}, 404
        email = (email or "").strip().lower()
        if not EMAIL_RE.match(email):
            return {"erro": "Informe um e-mail válido"}, 400

        host = current_app.config.get("SMTP_HOST")
        if not host:
            return {"erro": "Envio de e-mail não está configurado"}, 503

        registros = RegistroDiario.listar_por_paciente(paciente_id)
        mensagem = self._conteudo(registros)
        email_mensagem = EmailMessage()
        email_mensagem["Subject"] = "Relatório mensal de saúde — Seniores"
        email_mensagem["From"] = current_app.config.get(
            "REPORT_FROM", current_app.config.get("SMTP_USER", "")
        )
        email_mensagem["To"] = email
        email_mensagem.set_content(mensagem)

        try:
            port = int(current_app.config.get("SMTP_PORT", 587))
            usuario = current_app.config.get("SMTP_USER")
            senha = current_app.config.get("SMTP_PASSWORD")
            with smtplib.SMTP(host, port, timeout=10) as servidor:
                servidor.starttls()
                if usuario and senha:
                    servidor.login(usuario, senha)
                servidor.send_message(email_mensagem)
        except Exception:
            return {"erro": "Não foi possível enviar o relatório"}, 502
        return {"status": "enviado", "mensagem": "Relatório enviado com sucesso"}, 202

    @staticmethod
    def _conteudo(registros):
        linhas = [
            "Relatório de saúde — Seniores",
            "",
            "Registros do diário:",
        ]
        if not registros:
            linhas.append("Nenhum registro diário encontrado.")
        for registro in registros:
            linhas.append(
                f"- {registro.data}: humor={registro.humor}, dor={registro.dor}, "
                f"apetite={registro.apetite}, mobilidade={registro.mobilidade}; "
                f"observações={registro.observacoes or '-'}"
            )
        return "\n".join(linhas)
