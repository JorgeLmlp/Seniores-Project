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

    @classmethod
    def criar_ou_atualizar(cls, paciente, responsavel):
        """Persiste o responsavel principal e o vinculo em uma transacao."""
        try:
            paciente.responsavel_id = responsavel.id
            vinculo = db.session.get(cls, (paciente.id, responsavel.id))
            criado = vinculo is None
            if criado:
                vinculo = cls(paciente_id=paciente.id, responsavel_id=responsavel.id)
                db.session.add(vinculo)
            db.session.commit()
            return vinculo, criado
        except Exception:
            db.session.rollback()
            return None, False
    
