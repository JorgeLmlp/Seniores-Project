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
    humor_nivel = db.Column(db.Integer, nullable=True)
    dor_nivel = db.Column(db.Integer, nullable=True)
    apetite_nivel = db.Column(db.Integer, nullable=True)
    mobilidade_nivel = db.Column(db.Integer, nullable=True)
    incidentes = db.Column(db.JSON, nullable=True)
    duvidas = db.Column(db.Text, nullable=True)

    CAMPOS_EDITAVEIS = {
        "humor", "dor", "fome", "mobilidade", "descricao", "humor_nivel",
        "dor_nivel", "apetite_nivel", "mobilidade_nivel", "incidentes", "duvidas",
    }

    @property
    def to_dict(self):
        return {
            "id": self.id, "paciente_id": self.paciente_id,
            "humor": self.humor.value, "dor": self.dor.value,
            "fome": self.fome.value, "mobilidade": self.mobilidade.value,
            "descricao": self.descricao,
            "humor_nivel": self.humor_nivel, "dor_nivel": self.dor_nivel,
            "apetite_nivel": self.apetite_nivel,
            "mobilidade_nivel": self.mobilidade_nivel,
            "incidentes": self.incidentes or [], "duvidas": self.duvidas,
            "data_criacao": self.data_criacao.isoformat() if self.data_criacao else None,
            "data_alteracao": self.data_alteracao.isoformat() if self.data_alteracao else None,
        }
