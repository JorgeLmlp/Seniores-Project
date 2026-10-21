"""Montagem do historico consolidado e envio opcional por e-mail."""

from email.message import EmailMessage
from datetime import datetime
import os
import smtplib

from models.paciente.estoque import Estoque
from repositories import paciente_repository, relatorio_repository


class RelatorioService:
    def evolucao_sinais_vitais(self, paciente_id):
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        sinais = list(reversed(paciente_repository.listar_sinais_vitais(paciente_id)))
        campos = ("pressao_art", "glicemia", "temperatura", "freq_cardiaca", "saturacao")
        return {
            "labels": [sinal.data.isoformat() for sinal in sinais],
            "series": {campo: [getattr(sinal, campo) for sinal in sinais] for campo in campos},
        }, 200

    def alertas_estoque(self, paciente_id):
        if not paciente_repository.buscar_paciente(paciente_id):
            return None, 404
        itens = [
            item for item in paciente_repository.listar_registros(Estoque, paciente_id)
            if item.estoque_baixo
        ]
        return [{
            "tipo": "estoque_baixo", "titulo": "Estoque baixo",
            "mensagem": f"{item.nome} esta com {item.quantidade} unidade(s)",
            "estoque_id": item.id, "quantidade": item.quantidade,
            "quantidade_minima": item.quantidade_minima,
        } for item in itens], 200

    def gerar(self, paciente_id, ano=None, mes=None):
        agora = datetime.now()
        ano = agora.year if ano is None else ano
        mes = agora.month if mes is None else mes
        if not isinstance(ano, int) or not isinstance(mes, int) or not 1 <= mes <= 12 or not 1 <= ano <= 9998:
            return None, 400
        historico = relatorio_repository.consultar_historico_mensal(paciente_id, ano, mes)
        if not historico:
            return None, 404
        from services.paciente.relatorio_pdf import gerar_pdf_clinico
        return gerar_pdf_clinico(historico), 200

    def enviar_email(self, paciente_id, destinatario, ano=None, mes=None):
        if not destinatario or "@" not in destinatario:
            return False, 400
        pdf, status = self.gerar(paciente_id, ano, mes)
        if status != 200:
            return False, status
        host = os.getenv("SMTP_HOST")
        remetente = os.getenv("SMTP_FROM")
        if not host or not remetente:
            return False, 503
        mensagem = EmailMessage()
        mensagem["Subject"] = "Historico de saude"
        mensagem["From"] = remetente
        mensagem["To"] = destinatario
        mensagem.set_content("Segue em anexo o historico consolidado de saude.")
        mensagem.add_attachment(pdf, maintype="application", subtype="pdf", filename="historico-saude.pdf")
        try:
            with smtplib.SMTP(host, int(os.getenv("SMTP_PORT", "587")), timeout=15) as smtp:
                if os.getenv("SMTP_TLS", "1") == "1":
                    smtp.starttls()
                if os.getenv("SMTP_USER"):
                    smtp.login(os.getenv("SMTP_USER"), os.getenv("SMTP_PASSWORD", ""))
                smtp.send_message(mensagem)
            return True, 202
        except (OSError, smtplib.SMTPException):
            return False, 502
