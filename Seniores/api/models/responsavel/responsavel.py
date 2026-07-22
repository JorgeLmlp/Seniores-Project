from ..user import Usuario
from extensions import db


class Responsavel(Usuario):
    """Usuario que acompanha um ou mais pacientes."""

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
        # A tabela intermediaria permite que paciente e responsavel tenham varios vinculos.
        secondary="paciente_responsavel",
        back_populates="responsaveis"
    )

    __mapper_args__ = {
        "polymorphic_identity": "responsavel"
    }
