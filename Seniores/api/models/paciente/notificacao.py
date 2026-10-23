from datetime import datetime

from extensions import db


class Notificacao(db.Model):
    """Notificacao centralizada gerada a partir dos modulos do paciente."""

    __tablename__ = "notificacoes"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    chave = db.Column(db.String(160), unique=True, nullable=False)
    tipo = db.Column(db.String(50), nullable=False)
    referencia_id = db.Column(db.Integer, nullable=True)
    titulo = db.Column(db.String(160), nullable=False)
    mensagem = db.Column(db.String(500), nullable=False)
    lida = db.Column(db.Boolean, nullable=False, default=False)
    criado_em = db.Column(db.DateTime, default=datetime.now, nullable=False)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "chave": self.chave,
            "tipo": self.tipo,
            "referencia_id": self.referencia_id,
            "titulo": self.titulo,
            "mensagem": self.mensagem,
            "lida": self.lida,
            "criado_em": self.criado_em.isoformat() if self.criado_em else None,
        }

    @classmethod
    def buscar_por_chave(cls, chave):
        return db.session.scalar(db.select(cls).where(cls.chave == chave))

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls)
            .where(cls.paciente_id == paciente_id)
            .order_by(cls.lida, cls.criado_em.desc())
        ).all()

    def salvar(self):
        try:
            db.session.add(self)
            db.session.commit()
            return self
        except Exception:
            db.session.rollback()
            return None

    def marcar(self, lida):
        self.lida = lida
        return self.salvar()
