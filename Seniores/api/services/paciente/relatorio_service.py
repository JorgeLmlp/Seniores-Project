"""Montagem do historico consolidado e envio opcional por e-mail."""

from email.message import EmailMessage
from datetime import datetime, timedelta
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

    @staticmethod
    def _periodo(ano=None, mes=None, inicio=None, fim=None, todo_historico=False):
        """Intervalo inclusivo em datas; internamente fim é exclusivo."""
        if not isinstance(todo_historico, bool):
            raise ValueError('todo_historico deve ser booleano')
        if todo_historico:
            if any(v is not None for v in (ano, mes, inicio, fim)):
                raise ValueError('Nao misture todo_historico com outros filtros')
            return datetime(1900, 1, 1), datetime.now() + timedelta(days=1), 'todo'
        if inicio is not None or fim is not None:
            if not isinstance(inicio, str) or not isinstance(fim, str) or ano is not None or mes is not None:
                raise ValueError('Informe inicio e fim sem mes ou ano')
            try:
                d1 = datetime.strptime(inicio, '%Y-%m-%d')
                d2 = datetime.strptime(fim, '%Y-%m-%d')
            except ValueError as erro:
                raise ValueError('Datas devem seguir AAAA-MM-DD') from erro
            if d1 > d2 or (d2 - d1).days > 3660:
                raise ValueError('Intervalo invalido ou superior a dez anos')
            return d1, d2 + timedelta(days=1), 'intervalo'
        agora = datetime.now()
        ano = agora.year if ano is None else ano
        mes = agora.month if mes is None else mes
        if type(ano) is not int or type(mes) is not int or not 1 <= ano <= 9998 or not 1 <= mes <= 12:
            raise ValueError('Mes e ano invalidos')
        return datetime(ano, mes, 1), datetime(ano + (mes == 12), 1 if mes == 12 else mes + 1, 1), 'mensal'

    def gerar(self, paciente_id, ano=None, mes=None, inicio=None, fim=None, todo_historico=False):
        try:
            data_inicio, data_fim, modo = self._periodo(ano, mes, inicio, fim, todo_historico)
        except ValueError:
            return None, 400
        historico = relatorio_repository.consultar_historico_periodo(paciente_id, data_inicio, data_fim)
        if historico is None:
            return None, 404
        historico['periodo']['modo'] = modo
        from services.paciente.relatorio_pdf import gerar_pdf_clinico
        return gerar_pdf_clinico(historico), 200

    def enviar_email(self, paciente_id, destinatario, ano=None, mes=None,
                     inicio=None, fim=None, todo_historico=False):
        if not isinstance(destinatario, str) or not destinatario.strip() or "@" not in destinatario:
            return False, 400
        pdf, status = self.gerar(paciente_id, ano, mes, inicio, fim, todo_historico)
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
