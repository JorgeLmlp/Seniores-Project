from datetime import datetime

from extensions import db


class ItemEstoque(db.Model):
    """Item de estoque associado a um paciente."""

    __tablename__ = "itens_estoque"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    nome = db.Column(db.String(120), nullable=False)
    categoria = db.Column(db.String(80), nullable=True)
    quantidade = db.Column(db.Integer, nullable=False, default=0)
    quantidade_minima = db.Column(db.Integer, nullable=False, default=0)
    unidade = db.Column(db.String(30), nullable=True)
    observacoes = db.Column(db.String(500), nullable=True)
    atualizado_em = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "nome": self.nome,
            "categoria": self.categoria,
            "quantidade": self.quantidade,
            "quantidade_minima": self.quantidade_minima,
            "unidade": self.unidade,
            "observacoes": self.observacoes,
            "atualizado_em": self.atualizado_em.isoformat() if self.atualizado_em else None,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.nome)
        ).all()

    @classmethod
    def buscar_por_id(cls, item_id):
        return db.session.get(cls, item_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        item = cls(paciente_id=paciente_id, **dados)
        return item.salvar()

    def atualizar(self, dados):
        for campo, valor in dados.items():
            setattr(self, campo, valor)
        return self.salvar()

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
