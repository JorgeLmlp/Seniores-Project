from cuidador import User, Paciente
from extensions import db


class Responsavel(User):
    __tablename__ = 'responsaveis'
    id = db.Column(db.Integer, db.ForeignKey('users.id'), primary_key=True)
    relationship = db.Column(db.String(50), nullable=True)
    paciente : Paciente  = db.relationship('Paciente', backref='Responsavel', uselist=False)
    #TODO cuidador nullable, objeto classe Cuidador
    __mapper_args__ = {
        'polymorphic_identity': 'responsavel'
    }
    
     
     
    