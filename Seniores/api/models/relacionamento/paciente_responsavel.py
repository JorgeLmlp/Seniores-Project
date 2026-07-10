from extensions import db

class Paciente_responsavel(db.Model):
    __tablename__ = "paciente_responsavel"
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
    