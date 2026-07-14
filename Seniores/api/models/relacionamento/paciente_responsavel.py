from extensions import db

class Paciente_responsavel(db.Model):
    __tablename__ = "paciente_responsavel"
    paciente_id = db.Column(
        db.Integer, db.ForeignKey("pacientes.id"), primary_key=True
    )
    responsavel_id = db.Column(
        db.Integer, db.ForeignKey("responsaveis.id"), primary_key=True
    )
    
