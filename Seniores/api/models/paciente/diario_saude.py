import enum

from .base_info import Base_info
from extensions import db


class STATUS_DIARIO(enum.Enum):
    BOM = "bom"
    RUIM = "ruim"
    PESSIMO = "pessimo"
    RAZOAVEL = "razoavel"


class DiarioSaude(Base_info):
    __tablename__ = "diarios_saude"

    humor = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    dor = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    fome = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    mobilidade = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    descricao = db.Column(db.Text, nullable = True)

    CAMPOS_EDITAVEIS = {"humor", "dor", "fome", "mobilidade", "descricao"}

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "humor": self.humor.value, "dor": self.dor.value,
            "fome": self.fome.value, "mobilidade": self.mobilidade.value,
            "descricao": self.descricao,
            "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
            "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None,
        }
