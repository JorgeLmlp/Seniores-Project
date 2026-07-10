import datetime
from extensions import db
from models.cuidador.cuidador import Usuario


# Tabela de relacionamento entre Paciente e Responsavel
paciente_responsavel = db.Table(
    "paciente_responsavel",

    db.Column(
        "paciente_id",
        db.Integer,
        db.ForeignKey("pacientes.id"),
        primary_key=True
    ),

    db.Column(
        "responsavel_id",
        db.Integer,
        db.ForeignKey("responsaveis.id"),
        primary_key=True
    )
)


class Paciente(Usuario):
    __tablename__ = "pacientes"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    responsaveis = db.relationship(
        "Responsavel",
        secondary=paciente_responsavel,
        back_populates="pacientes"
    )

    __mapper_args__ = {
        "polymorphic_identity": "paciente"
    }

    def vincular_responsavel(self, responsavel):
        self.responsaveis.append(responsavel)


class SinalVital(db.Model):
    __tablename__ = "sinais_vitais"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    data = db.Column(
        db.DateTime,
        default=datetime.datetime.utcnow
    )

    freq_cardiaca = db.Column(db.String(30))
    saturacao = db.Column(db.String(30))
    pressao_art = db.Column(db.String(30))
    glicemia = db.Column(db.String(30))
    temperatura = db.Column(db.String(30))


class LstSinaisVit(db.Model):
    __tablename__ = "lst_sinais_vit"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    data = db.Column(db.DateTime)
    freqCardiaca = db.Column(db.String(30))
    pressaoArterial = db.Column(db.String(30))
    saturacao = db.Column(db.String(30))
    glicemia = db.Column(db.String(30))
    temperatura = db.Column(db.String(30))