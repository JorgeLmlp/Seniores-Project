from extensions import db
class Usuario(db.Model):
    """Campos compartilhados pelas tres tabelas de usuarios.

    A classe e abstrata: ela nao cria uma tabela `usuarios`; cada tipo possui
    sua propria tabela, mas reutiliza estas colunas.
    """

    __abstract__ = True
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    phoneNumber = db.Column(db.String(20), nullable=False)
    tipo = db.Column(db.String(20))
    cpf = db.Column(db.String(14), unique=True, nullable=False)

    __mapper_args__ = {
        # SQLAlchemy usa `tipo` para identificar a subclasse carregada.
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
        # Nunca devolve password, mesmo ela existindo no registro.
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phoneNumber': self.phoneNumber,
            'cpf': self.cpf,
            'tipo': self.tipo,
        }
