
from extensions import db
from ..user import Usuario



class Cuidador(Usuario):
    __tablename__ = 'cuidadores'
    __allow_unmapped__ = True
    id = db.Column(db.Integer, primary_key=True)
    experience = db.Column(db.String(255), nullable=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'))
    __mapper_args__ = {
        'polymorphic_identity': 'cuidador'
    }

    
#TODO
#     def registrar_sinais_vit(
#     self,
#     data: datetime,
#     freq_cardiaca: str,
#     saturacao: str,
#     pressao_art: str,
#     glicemia: str,
#     temperatura: str
# ):
#         cuidadores = db.relationship(
            
#         )
#         from models.paciente import SinalVital
        
        

    
        
