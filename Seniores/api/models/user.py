from extensions import db
from werkzeug.security import check_password_hash, generate_password_hash
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

    @classmethod
    def buscar_por_id(cls, usuario_id):
        return db.session.get(cls, usuario_id)

    @classmethod
    def buscar_por_cpf(cls, cpf):
        return db.session.scalar(db.select(cls).where(cls.cpf == cpf))

    @classmethod
    def buscar_por_email(cls, email):
        return db.session.scalar(db.select(cls).where(cls.email == email))

    def senha_confere(self, senha):
        """Valida a senha recebida contra o hash armazenado no banco."""
        return check_password_hash(self.password, senha)

    @classmethod
    def listar(cls):
        return db.session.scalars(db.select(cls)).all()

    @classmethod
    def email_ou_cpf_existe(cls, modelos, email, cpf, usuario_id=None):
        """Verifica unicidade entre todos os tipos de usuario informados."""
        for modelo in modelos:
            consulta = db.select(modelo).where(
                (modelo.email == email) | (modelo.cpf == cpf)
            )
            if modelo is cls and usuario_id is not None:
                consulta = consulta.where(modelo.id != usuario_id)
            if db.session.scalar(consulta):
                return True
        return False

    @classmethod
    def criar(cls, dados):
        usuario = cls(
            name=dados["nome"], email=dados["email"],
            password=generate_password_hash(dados["senha"]),
            phoneNumber=dados["telefone"], cpf=dados["cpf"], tipo=dados["tipo"],
        )
        return cls.salvar(usuario)

    def atualizar(self, info):
        """Atualiza somente campos recebidos, incluindo hash para a senha."""
        campos = {
            "nome": "name", "name": "name", "email": "email",
            "telefone": "phoneNumber", "phoneNumber": "phoneNumber", "cpf": "cpf",
        }
        for chave, atributo in campos.items():
            if chave in info:
                setattr(self, atributo, info[chave])
        senha = info.get("senha") or info.get("password")
        if senha:
            self.password = generate_password_hash(senha)
        return self.salvar(self)

    @staticmethod
    def salvar(usuario):
        try:
            db.session.add(usuario)
            db.session.commit()
            return usuario
        except Exception:
            db.session.rollback()
            return None

    def deletar(self):
        try:
            db.session.delete(self)
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            return False

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
