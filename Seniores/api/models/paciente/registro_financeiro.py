from datetime import datetime

from extensions import db

from .base_info import Base_info


class RegistroFinanceiro(Base_info):
    """Receita ou despesa vinculada aos cuidados do paciente."""

    __tablename__ = "registros_financeiros"

    descricao = db.Column(db.String(255), nullable=False)
    valor = db.Column(db.Numeric(10, 2), nullable=False)
    tipo = db.Column(db.String(20), nullable=False)  # receita ou despesa
    data = db.Column(db.DateTime, default=datetime.now, nullable=False)
    CAMPOS_EDITAVEIS = {"descricao", "valor", "tipo", "data"}

    @property
    def to_dict(self):
        return {"id": self.id, "paciente_id": self.paciente_id,
                "descricao": self.descricao, "valor": float(self.valor), "tipo": self.tipo,
                "data": self.data.isoformat() if self.data else None,
                "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
                "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None}
