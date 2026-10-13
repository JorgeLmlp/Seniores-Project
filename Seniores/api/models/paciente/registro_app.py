from datetime import datetime

from extensions import db


class RegistroApp(db.Model):
    """Registro flexivel usado pelas telas de agenda e comunicacao do Flutter."""

    __tablename__ = "registros_app"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer, db.ForeignKey("pacientes.id"), nullable=False, index=True
    )
    recurso = db.Column(db.String(30), nullable=False, index=True)
    dados = db.Column(db.JSON, nullable=False)
    data_criacao = db.Column(db.DateTime, default=datetime.now, nullable=False)
    data_alteracao = db.Column(db.DateTime, nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "recurso": self.recurso,
            "dados": self.dados,
            "data_criacao": self.data_criacao.isoformat(),
            "data_alteracao": (
                self.data_alteracao.isoformat() if self.data_alteracao else None
            ),
        }

    def salvar(self):
        try:
            db.session.add(self)
            db.session.commit()
            return self
        except Exception:
            db.session.rollback()
            return None

    def deletar(self):
        try:
            db.session.delete(self)
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            return False

