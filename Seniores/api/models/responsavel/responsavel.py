from ..user import Usuario
from extensions import db


class Responsavel(Usuario):
    __tablename__ = "responsaveis"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    relationship = db.Column(
        db.String(50),
        nullable=True
    )

    pacientes = db.relationship(
        "Paciente",
        secondary="paciente_responsavel",
        back_populates="responsaveis"
    )

    __mapper_args__ = {
        "polymorphic_identity": "responsavel"
    }
