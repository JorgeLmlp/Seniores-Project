from extensions import db
from datetime import datetime

class SinalVital(db.Model):
    """Model alternativo de sinais vitais; espelha a tabela sinais_vitais."""
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
