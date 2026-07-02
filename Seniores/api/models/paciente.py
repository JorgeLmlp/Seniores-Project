import datetime
from extensions import db
from models.cuidador import Usuario


class Paciente(Usuario):
    __tablename__ = "pacientes"
    __allow_unmapped__ = True
    id = db.Column(db.Integer, db.ForeignKey('users.id'), primary_key=True)

    responsavel_id = db.Column(db.Integer, db.ForeignKey('responsaveis.id'))
    lst_sinais_vit_id = db.Column(db.Integer, db.ForeignKey('lst_sinais_vit.id'))
    responsavel = db.relationship('Responsavel', backref='pacientes')

    __mapper_args__ = {
        'polymorphic_identity': 'paciente'
    }

    def vincularResponsavel(self, responsavel):
        self.responsavel = responsavel


class SinalVital(db.Model):
    __tablename__ = "sinais_vitais"

    id = db.Column(db.Integer, primary_key=True)

    data = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    freq_cardiaca = db.Column(db.String(30))
    saturacao = db.Column(db.String(30))
    pressao_art = db.Column(db.String(30))
    glicemia = db.Column(db.String(30))
    temperatura = db.Column(db.String(30))


class LstSinaisVit(db.Model):
    __tablename__ = "lst_sinais_vit"

    id = db.Column(db.Integer, primary_key=True)

    data = db.Column(db.DateTime)
    freqCardiaca = db.Column(db.String(30))
    pressaoArterial = db.Column(db.String(30))
    saturacao = db.Column(db.String(30))
    glicemia = db.Column(db.String(30))
    temperatura = db.Column(db.String(30))