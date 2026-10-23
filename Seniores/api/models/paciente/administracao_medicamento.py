from datetime import datetime

from extensions import db


class AdministracaoMedicamento(db.Model):
    __tablename__ = "administracoes_medicamentos"

    id = db.Column(db.Integer, primary_key=True)
    medicamento_id = db.Column(
        db.Integer, db.ForeignKey("tbl_remedio.id", ondelete="CASCADE"), nullable=False, index=True
    )
    horario = db.Column(db.String(10), nullable=False)
    administrado_em = db.Column(db.DateTime, default=datetime.now, nullable=False)
    responsavel_id = db.Column(db.Integer, nullable=True)
    observacao = db.Column(db.String(500), nullable=True)

    medicamento = db.relationship("Remedio", back_populates="administracoes")

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "medicamento_id": self.medicamento_id,
            "horario": self.horario,
            "administrado_em": (
                self.administrado_em.isoformat() if self.administrado_em else None
            ),
            "responsavel_id": self.responsavel_id,
            "observacao": self.observacao,
        }
