from extensions import db

from .base_info import Base_info


class Lesao(Base_info):
    """Acompanhamento de lesoes observadas no paciente."""

    __tablename__ = "lesoes"

    localizacao = db.Column(db.String(100), nullable=False)
    descricao = db.Column(db.Text, nullable=False)
    gravidade = db.Column(db.String(30), nullable=True)
    status = db.Column(db.String(30), nullable=False, default="aberta")
    # A imagem fica no banco; o MIME permite devolve-la com o Content-Type correto.
    foto = db.Column(db.LargeBinary, nullable=True)
    foto_mime = db.Column(db.String(50), nullable=True)
    CAMPOS_EDITAVEIS = {"localizacao", "descricao", "gravidade", "status", "foto", "foto_mime"}

    @property
    def to_dict(self):
        return {"id": self.id, "paciente_id": self.paciente_id,
                "localizacao": self.localizacao, "descricao": self.descricao,
                "gravidade": self.gravidade, "status": self.status,
                "foto_url": f"/lesoes/{self.id}/foto" if self.foto else None,
                "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
                "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None}
