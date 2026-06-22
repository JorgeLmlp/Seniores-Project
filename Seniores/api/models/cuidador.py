
from extensions import db
from datetime import datetime

#classe abstrata NAO IMSTAMCIAR
class Usuario(db.Model):
    __abstract__ = True
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)
    phoneNumber = db.Column(db.String(20),  nullable=False)
    type = db.Column(db.String(20))

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

    id = db.Column(db.Integer, db.ForeignKey('users.id'), primary_key=True)
    experience = db.Column(db.String(255), nullable=True)
    paciente_id = db.column(db.Integer, db.ForeingKey('Paciente.id'))

    __mapper_args__ = {
        'polymorphic_identity': 'cuidador'
    }

    def to_dict(self):
        dados = super().to_dict
        dados['experience'] = self.experience
        return dados

    def registrar_sinais_vit(
    self,
    data: datetime,
    freq_cardiaca: str,
    saturacao: str,
    pressao_art: str,
    glicemia: str,
    temperatura: str
):
        from models.paciente import SinalVital
        
        

    
        
