from datetime import datetime

from extensions import db


class Comunicado(db.Model):
    """Mensagem enviada pelo paciente a cuidadores ou responsáveis vinculados."""

    __tablename__ = "comunicados"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer, db.ForeignKey("pacientes.id"), nullable=False, index=True
    )
    titulo = db.Column(db.String(160), nullable=False)
    mensagem = db.Column(db.String(2000), nullable=False)
    destinatarios = db.Column(db.JSON, nullable=False, default=list)
    status = db.Column(db.String(20), nullable=False, default="enviado")
    criado_em = db.Column(db.DateTime, default=datetime.now, nullable=False)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "titulo": self.titulo,
            "mensagem": self.mensagem,
            "destinatarios": self.destinatarios or [],
            "status": self.status,
            "criado_em": self.criado_em.isoformat() if self.criado_em else None,
        }
