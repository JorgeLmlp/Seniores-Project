from extensions import db
from werkzeug.security import generate_password_hash


def _aplicar_dados(usuario, info):
    if 'nome' in info:
        usuario.name = info.get('nome')
    if 'name' in info:
        usuario.name = info.get('name')
    if 'email' in info:
        usuario.email = info.get('email')
    if 'telefone' in info:
        usuario.phoneNumber = info.get('telefone')
    if 'phoneNumber' in info:
        usuario.phoneNumber = info.get('phoneNumber')
    if 'cpf' in info:
        usuario.cpf = info.get('cpf')
    if 'senha' in info and info.get('senha'):
        usuario.password = generate_password_hash(info.get('senha'))
    if 'password' in info and info.get('password'):
        usuario.password = generate_password_hash(info.get('password'))


## classe abstrata usuario ##
class Usuario(db.Model):
    __abstract__ = True
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)
    phoneNumber = db.Column(db.String(20), nullable=False)
    tipo = db.Column(db.String(20))
    cpf = db.Column(db.String(14), unique=True, nullable=False)

    __mapper_args__ = {
        'polymorphic_on': 'tipo',
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
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phoneNumber': self.phoneNumber,
            'cpf': self.cpf,
            'tipo': self.tipo,
        }