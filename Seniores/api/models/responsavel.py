from .cuidador import Usuario
from .paciente import Paciente
from extensions import db


class Responsavel(Usuario):
    __tablename__ = 'responsaveis'
    __allow_unmapped__ = True
    id = db.Column(db.Integer,primary_key=True)
    relationship = db.Column(db.String(50), nullable=True)
    paciente : Paciente  = db.relationship('Paciente', backref='Responsavel', uselist=False)
    #TODO cuidador nullable, objeto classe Cuidador
    __mapper_args__ = {
        'polymorphic_identity': 'responsavel'
    }
    
     
     
    