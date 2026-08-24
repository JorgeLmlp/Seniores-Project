from extensions import db

from .base_info import Base_info


class Estoque(Base_info):
    """Item de estoque de uso do paciente."""

    __tablename__ = "estoques"

    nome = db.Column(db.String(100), nullable=False)
    quantidade = db.Column(db.Integer, nullable=False, default=0)
    quantidade_minima = db.Column(db.Integer, nullable=True)
    descricao = db.Column(db.String(255), nullable=True)
    CAMPOS_EDITAVEIS = {"nome", "quantidade", "quantidade_minima", "descricao"}

    @property
    def to_dict(self):
        return {"id": self.id, "paciente_id": self.paciente_id, "nome": self.nome,
                "quantidade": self.quantidade, "quantidade_minima": self.quantidade_minima,
                "descricao": self.descricao,
                "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
                "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None}
