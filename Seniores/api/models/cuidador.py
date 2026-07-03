
from extensions import db
from datetime import datetime

class Usuario(db.Model):
    __abstract__ = True
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)
    phoneNumber = db.Column(db.String(20),  nullable=False)
    tpo = db.Column(db.String(20))
    cpf = db.Column(db.String(14), unique=True, nullable=False)

    __mapper_args__ = {
        'polymorphic_on':       type,
        'polymorphic_identity': 'user'
    }

    
    def __str__(self):
        return (
            f"User(id={self.id}, name='{self.name}', "
            f"email='{self.email}', phoneNumber='{self.phoneNumber}')"
        )
    def __repr__(self):
        return self.__str__()
    
    @property
    def to_dict(self):
        return {
            'id':          self.id,
            'name':        self.name,
            'email':       self.email,
            'phoneNumber': self.phoneNumber
        }

    def trocarSenha(self, new_password):
        self.password = new_password

    def trocarNumeroTelefone(self, new_phone_number):
        self.phoneNumber = new_phone_number

    def trocarEmail(self, new_email):
        self.email = new_email

    def trocarNome(self, new_name):
        self.name = new_name
        
    def autenticar(self):
        pass
    



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
        
        

    
        
