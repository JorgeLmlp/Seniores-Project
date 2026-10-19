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
    def estoque_baixo(self):
        return self.quantidade_minima is not None and self.quantidade <= self.quantidade_minima

    @property
    def to_dict(self):
        return {"id": self.id, "paciente_id": self.paciente_id, "nome": self.nome,
                "quantidade": self.quantidade, "quantidade_minima": self.quantidade_minima,
                "descricao": self.descricao, "estoque_baixo": self.estoque_baixo,
                "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
                "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None}
