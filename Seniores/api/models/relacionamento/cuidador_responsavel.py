from extensions import db


class CuidadorResponsavel(db.Model):
    """Tabela de juncao para o vinculo muitos-para-muitos."""

    __tablename__ = "cuidador_responsavel"

    cuidador_id = db.Column(
        db.Integer, db.ForeignKey("cuidadores.id"), primary_key=True
    )
    responsavel_id = db.Column(
        db.Integer, db.ForeignKey("responsaveis.id"), primary_key=True
    )

    @classmethod
    def criar_ou_buscar(cls, cuidador, responsavel):
        try:
            vinculo = db.session.get(cls, (cuidador.id, responsavel.id))
            if vinculo:
                return vinculo, False
            vinculo = cls(cuidador_id=cuidador.id, responsavel_id=responsavel.id)
            db.session.add(vinculo)
            db.session.commit()
            return vinculo, True
        except Exception:
            db.session.rollback()
            return None, False
