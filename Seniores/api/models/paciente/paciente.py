import datetime
from extensions import db
from ..user import Usuario


# Tabela de relacionamento entre Paciente e Responsavel


class Paciente(Usuario):
    """Usuario que possui responsaveis, medicamentos e sinais vitais."""

    __tablename__ = "pacientes"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # Responsável principal, disponível diretamente na tabela pacientes.
    # A relação muitos-para-muitos em ``responsaveis`` continua sendo usada
    # para os demais vínculos.
    responsavel_id = db.Column(
        db.Integer,
        db.ForeignKey("responsaveis.id"),
        nullable=True,
    )

    responsavel = db.relationship(
        "Responsavel",
        foreign_keys=[responsavel_id],
    )

    responsaveis = db.relationship(
        "Responsavel",
        secondary="paciente_responsavel",
        back_populates="pacientes"
    )

    remedios = db.relationship(
        "Remedio",
        back_populates="paciente",
        # Ao remover um paciente, remove tambem medicamentos que nao fazem sentido sem ele.
        cascade="all, delete-orphan",
        # A lista recebida pelo codigo ja vem em ordem alfabetica.
        order_by="Remedio.nome",
    )

    __mapper_args__ = {
        "polymorphic_identity": "paciente"
    }

    


class SinalVital(db.Model):
    """Registro pontual das medidas clinicas de um paciente."""
    __tablename__ = "sinais_vitais"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    data = db.Column(
        db.DateTime,
        default=datetime.datetime.now
    )
    db.relationship(
        "Paciente",
        back_populates="sinais_vitais"
    )
    freq_cardiaca = db.Column(db.String(30))
    saturacao = db.Column(db.String(30))
    pressao_art = db.Column(db.String(30))
    glicemia = db.Column(db.String(30))
    temperatura = db.Column(db.String(30))


