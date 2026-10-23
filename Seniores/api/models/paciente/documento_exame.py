from datetime import datetime

from extensions import db


class DocumentoExame(db.Model):
    __tablename__ = "documentos_exames"

    id = db.Column(db.Integer, primary_key=True)
    exame_id = db.Column(
        db.Integer, db.ForeignKey("exames.id", ondelete="CASCADE"), nullable=False, index=True
    )
    nome = db.Column(db.String(255), nullable=False)
    nome_armazenado = db.Column(db.String(255), nullable=False, unique=True)
    mime_type = db.Column(db.String(120), nullable=False)
    tamanho = db.Column(db.Integer, nullable=False)
    criado_em = db.Column(db.DateTime, default=datetime.now, nullable=False)

    exame = db.relationship("Exame", back_populates="documentos")

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "exame_id": self.exame_id,
            "nome": self.nome,
            "mime_type": self.mime_type,
            "tamanho": self.tamanho,
            "criado_em": self.criado_em.isoformat() if self.criado_em else None,
        }
