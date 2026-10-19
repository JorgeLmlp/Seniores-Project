"""Montagem do historico consolidado e envio opcional por e-mail."""

from email.message import EmailMessage
from datetime import datetime
import os
import smtplib
import textwrap

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
        ano = ano or agora.year
        mes = mes or agora.month
        if not isinstance(ano, int) or not isinstance(mes, int) or not 1 <= mes <= 12:
            return None, 400
        historico = relatorio_repository.consultar_historico_mensal(paciente_id, ano, mes)
        if not historico:
            return None, 404
        paciente = historico["paciente"]
        linhas = [
            "RELATORIO MENSAL CONSOLIDADO DE SAUDE",
            f"Periodo: {mes:02d}/{ano}",
            f"Paciente: {paciente.name}",
            f"Idade: {paciente.idade or 'nao informada'}",
            f"Tipo sanguineo: {paciente.tipo_sanguineo or 'nao informado'}",
            "",
        ]
        self._secao(linhas, "MEDICAMENTOS", historico["medicamentos"], lambda r: f"{r.nome} - {r.dosagem} - {r.frequencia or 'sem frequencia'}")
        self._secao(linhas, "ADMINISTRACOES", historico["administracoes"], lambda r: f"Medicamento #{r.medicamento_id} em {r.administrado_em.isoformat()} por {r.confirmado_por}")
        self._secao(linhas, "SINAIS VITAIS", historico["sinais_vitais"], lambda r: f"{r.data.isoformat()} | PA {r.pressao_art or '-'} | glicemia {r.glicemia or '-'} | temperatura {r.temperatura or '-'}")
        self._secao(linhas, "DIARIO DE SINTOMAS", historico["diarios"], lambda r: f"{r.data_criacao.isoformat()} | humor {r.humor.value} | apetite {r.fome.value} | sono {r.sono.value if r.sono else '-'}")
        self._secao(linhas, "INCIDENTES", historico["incidentes"], lambda r: f"{r.data_hora.isoformat()} | {r.tipo}: {r.descricao}")
        self._secao(linhas, "CONSULTAS", historico["consultas"], lambda r: str(r.dados))
        self._secao(linhas, "EXAMES AGENDADOS", historico["exames_agendados"], lambda r: str(r.dados))
        self._secao(linhas, "DOCUMENTOS DE EXAMES", historico["documentos_exames"], lambda r: f"{r.nome} - {r.nome_arquivo} ({r.mime_type})")
        self._secao(linhas, "DIETA E RESTRICOES", historico["dietas"], lambda r: f"Dieta: {r.descricao_dieta or '-'} | Restricoes: {', '.join(r.restricoes or [])}")
        self._secao(linhas, "CONTATOS DE EMERGENCIA", historico["contatos"], lambda r: f"{r.nome} ({r.tipo}) - {r.telefone}")
        self._secao(linhas, "ESTOQUE", historico["estoque"], lambda r: f"{r.nome}: {r.quantidade} (minimo {r.quantidade_minima if r.quantidade_minima is not None else '-'})")
        return self._pdf(linhas), 200

    @staticmethod
    def _secao(linhas, titulo, registros, formatar):
        linhas.extend([titulo, "-" * len(titulo)])
        linhas.extend(formatar(registro) for registro in registros)
        if not registros:
            linhas.append("Nenhum registro.")
        linhas.append("")

    @staticmethod
    def _pdf(linhas):
        # PDF textual simples, sem dependencia externa, suficiente para abrir,
        # imprimir e anexar em leitores padrao.
        comandos = ["BT", "/F1 10 Tf", "50 790 Td", "12 TL"]
        primeira = True
        for linha in linhas:
            for trecho in textwrap.wrap(str(linha), width=92) or [""]:
                texto = trecho.encode("latin-1", "replace").decode("latin-1")
                texto = texto.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
                if not primeira:
                    comandos.append("T*")
                comandos.append(f"({texto}) Tj")
                primeira = False
        comandos.append("ET")
        stream = "\n".join(comandos).encode("latin-1")
        objetos = [
            b"<< /Type /Catalog /Pages 2 0 R >>",
            b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
            b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        ]
        pdf = bytearray(b"%PDF-1.4\n")
        offsets = [0]
        for indice, objeto in enumerate(objetos, 1):
            offsets.append(len(pdf))
            pdf.extend(f"{indice} 0 obj\n".encode() + objeto + b"\nendobj\n")
        xref = len(pdf)
        pdf.extend(f"xref\n0 {len(objetos) + 1}\n0000000000 65535 f \n".encode())
        for offset in offsets[1:]:
            pdf.extend(f"{offset:010d} 00000 n \n".encode())
        pdf.extend(f"trailer << /Size {len(objetos) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF".encode())
        return bytes(pdf)

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
