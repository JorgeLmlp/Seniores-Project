import datetime
from cuidador import Usuario

from extensions import db

class Paciente(Usuario):
    id = db.column(db.Integer, db.ForeignKey('users.id'), primary_key=True)
    responsavel_id = db.column(db.relationship('Responsavel.id'), db.Integer)
    lst_sinais_vit_id = db.Column(
    db.Integer,
    db.ForeignKey('lst_sinais_vit.id')
)
    responsavel = db.relationship(
        'Responsavel',
        backref='pacientes'
    )
    
    __mapper_args__ = {
        'polymorphic_identity': 'responsavel'
    }
    
    def vincularResponsavel(self, responsavel):
        self.responsavel = responsavel
    


class SinalVital():
    def __init__(
            self,
            data: datetime,
            freq_cardiaca: str,
            saturacao: str,
            pressao_art: str,
            glicemia: str,
            temperatura: str
        ):
        self.data = data
        self.freq_cardiaca  = freq_cardiaca
        self.saturacao = saturacao
        self.pressao_art = pressao_art
        self.glicemia = glicemia
        self.temperatura = temperatura

        

class lstSinaisVit(db.model):
    __tablename__ = 'lst_sinais_vit'
    data = db.column()
    freqCardiaca = db.column(db.String(30), nullable = False)
    pressaoArterial = db.column()
    saturacao = db.column()
    glicemia = db.column()
    temperatura = db.column()
    
    __mapper_args__ = {
        'polymorphic_identity': 'responsavel'
    }