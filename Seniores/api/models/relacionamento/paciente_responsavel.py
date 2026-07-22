from extensions import db

class Paciente_responsavel(db.Model):
    """Tabela de juncao que materializa o vinculo paciente-responsavel."""

    __tablename__ = "paciente_responsavel"
    # As duas FKs formam a chave primaria e impedem vinculos duplicados.
    paciente_id = db.Column(
        db.Integer, db.ForeignKey("pacientes.id"), primary_key=True
    )
    responsavel_id = db.Column(
        db.Integer, db.ForeignKey("responsaveis.id"), primary_key=True
    )
    
