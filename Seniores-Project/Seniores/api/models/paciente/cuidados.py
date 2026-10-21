"""Models dos cuidados clinicos e administrativos do paciente.

As operacoes de banco ficam nestes models por decisao arquitetural do projeto;
services apenas validam e coordenam regras de negocio.
"""

from datetime import datetime

from extensions import db

from .base_info import Base_info


def _datas(registro):
    return {
        "data_criacao": registro.data_criacao.isoformat() if registro.data_criacao else None,
        "data_alteracao": registro.data_alteracao.isoformat() if registro.data_alteracao else None,
    }


class AdministracaoMedicamento(Base_info):
    __tablename__ = "administracoes_medicamentos"

    medicamento_id = db.Column(db.Integer, db.ForeignKey("tbl_remedio.id"), nullable=False, index=True)
    horario_previsto = db.Column(db.DateTime, nullable=True)
    administrado_em = db.Column(db.DateTime, default=datetime.now, nullable=False)
    confirmado_por = db.Column(db.String(100), nullable=False)
    observacao = db.Column(db.Text, nullable=True)
    CAMPOS_EDITAVEIS = {"medicamento_id", "horario_previsto", "administrado_em", "confirmado_por", "observacao"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "medicamento_id": self.medicamento_id,
            "horario_previsto": self.horario_previsto.isoformat() if self.horario_previsto else None,
            "administrado_em": self.administrado_em.isoformat() if self.administrado_em else None,
            "confirmado_por": self.confirmado_por, "observacao": self.observacao,
            **_datas(self),
        }


class ExameDocumento(Base_info):
    __tablename__ = "exames_documentos"

    nome = db.Column(db.String(120), nullable=False)
    descricao = db.Column(db.Text, nullable=True)
    data_exame = db.Column(db.DateTime, nullable=True)
    arquivo = db.Column(db.LargeBinary, nullable=False)
    nome_arquivo = db.Column(db.String(255), nullable=False)
    mime_type = db.Column(db.String(100), nullable=False)
    CAMPOS_EDITAVEIS = {"nome", "descricao", "data_exame", "arquivo", "nome_arquivo", "mime_type"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id, "nome": self.nome,
            "descricao": self.descricao,
            "data_exame": self.data_exame.isoformat() if self.data_exame else None,
            "nome_arquivo": self.nome_arquivo, "mime_type": self.mime_type,
            "arquivo_url": f"/exames-documentos/{self.id}/arquivo", **_datas(self),
        }


class Incidente(Base_info):
    __tablename__ = "incidentes"

    tipo = db.Column(db.String(50), nullable=False)
    data_hora = db.Column(db.DateTime, nullable=False, default=datetime.now)
    descricao = db.Column(db.Text, nullable=False)
    gravidade = db.Column(db.String(30), nullable=True)
    providencias = db.Column(db.Text, nullable=True)
    CAMPOS_EDITAVEIS = {"tipo", "data_hora", "descricao", "gravidade", "providencias"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id, "tipo": self.tipo,
            "data_hora": self.data_hora.isoformat() if self.data_hora else None,
            "descricao": self.descricao, "gravidade": self.gravidade,
            "providencias": self.providencias, **_datas(self),
        }


class ContatoEmergencia(Base_info):
    __tablename__ = "contatos_emergencia"

    nome = db.Column(db.String(100), nullable=False)
    tipo = db.Column(db.String(20), nullable=False)  # medico ou familiar
    vinculo = db.Column(db.String(60), nullable=True)
    telefone = db.Column(db.String(30), nullable=False)
    email = db.Column(db.String(120), nullable=True)
    especialidade = db.Column(db.String(100), nullable=True)
    CAMPOS_EDITAVEIS = {"nome", "tipo", "vinculo", "telefone", "email", "especialidade"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id, "nome": self.nome,
            "tipo": self.tipo, "vinculo": self.vinculo, "telefone": self.telefone,
            "email": self.email, "especialidade": self.especialidade, **_datas(self),
        }


class TurnoCuidador(Base_info):
    __tablename__ = "turnos_cuidadores"

    cuidador_id = db.Column(db.Integer, db.ForeignKey("cuidadores.id"), nullable=True, index=True)
    nome_cuidador = db.Column(db.String(100), nullable=False)
    dias_semana = db.Column(db.JSON, nullable=False)
    hora_inicio = db.Column(db.String(5), nullable=False)
    hora_fim = db.Column(db.String(5), nullable=False)
    observacao = db.Column(db.Text, nullable=True)
    CAMPOS_EDITAVEIS = {"cuidador_id", "nome_cuidador", "dias_semana", "hora_inicio", "hora_fim", "observacao"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "cuidador_id": self.cuidador_id, "nome_cuidador": self.nome_cuidador,
            "dias_semana": self.dias_semana, "hora_inicio": self.hora_inicio,
            "hora_fim": self.hora_fim, "observacao": self.observacao, **_datas(self),
        }


class DietaRestricao(Base_info):
    __tablename__ = "dietas_restricoes"

    descricao_dieta = db.Column(db.Text, nullable=True)
    restricoes = db.Column(db.JSON, nullable=False, default=list)
    alergias = db.Column(db.JSON, nullable=True)
    observacoes = db.Column(db.Text, nullable=True)
    CAMPOS_EDITAVEIS = {"descricao_dieta", "restricoes", "alergias", "observacoes"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "descricao_dieta": self.descricao_dieta,
            "restricoes": self.restricoes or [], "alergias": self.alergias or [],
            "observacoes": self.observacoes, **_datas(self),
        }


class PermissaoMembro(Base_info):
    __tablename__ = "permissoes_membros"

    membro_tipo = db.Column(db.String(20), nullable=False)
    membro_id = db.Column(db.Integer, nullable=False)
    nivel = db.Column(db.String(10), nullable=False)  # leitura ou escrita
    CAMPOS_EDITAVEIS = {"membro_tipo", "membro_id", "nivel"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "membro_tipo": self.membro_tipo, "membro_id": self.membro_id,
            "nivel": self.nivel, **_datas(self),
        }


class AlertaPanico(Base_info):
    __tablename__ = "alertas_panico"

    acionado_em = db.Column(db.DateTime, nullable=False, default=datetime.now)
    localizacao = db.Column(db.String(255), nullable=True)
    mensagem = db.Column(db.String(255), nullable=True)
    resolvido = db.Column(db.Boolean, nullable=False, default=False)
    CAMPOS_EDITAVEIS = {"localizacao", "mensagem", "resolvido"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "acionado_em": self.acionado_em.isoformat() if self.acionado_em else None,
            "localizacao": self.localizacao, "mensagem": self.mensagem,
            "resolvido": self.resolvido, **_datas(self),
        }
