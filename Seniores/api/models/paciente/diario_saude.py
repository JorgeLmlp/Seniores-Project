import enum
from base_info import Base_info
from extensions import db


class STATUS_DIARIO(enum.Enum):
    BOM = "bom",
    RUIM = "ruim"
    PESSIMO = "pessimo"
    RAZOAVEL = "razoavel"


class DiarioSaude(Base_info):
    humor = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    dor = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    fome = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    mobilidade = db.Column(db.Enum(STATUS_DIARIO), nullable = False)
    descricao = db.Column(db.Text, nullable = True)
    
    
    
    