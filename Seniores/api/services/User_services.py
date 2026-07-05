from repositories.user_repository import UserRepository
from werkzeug.security import generate_password_hash


def _normalizar_tipo(tipo):
    return (tipo or '').lower()


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


class UserService:
    def __init__(self):
        self.repository = UserRepository()

    def criar(self, info):
        nome = info.get('nome') or info.get('name')
        email = info.get('email')
        senha = info.get('senha') or info.get('password')
        telefone = info.get('telefone') or info.get('phoneNumber')
        cpf = info.get('cpf')
        tipo = _normalizar_tipo(info.get('tipo'))
        classe = self.repository.classe_por_tipo(tipo)

        if not all([nome, email, senha, telefone, cpf, classe]):
            return None, 400

        if self.repository.email_ou_cpf_existe(email, cpf):
            return None, 409

        usuario = self.repository.criar_usuario(
            tipo,
            nome,
            email,
            generate_password_hash(senha),
            telefone,
            cpf,
        )
        return usuario, 201

    def listar(self, tipo=None):
        usuarios = self.repository.listar(tipo)
        if usuarios is None:
            return None, 400
        return usuarios, 200

    def buscar_por_id(self, tipo, usuario_id):
        if not self.repository.classe_por_tipo(tipo):
            return None, 400

        usuario = self.repository.buscar_por_id(tipo, usuario_id)
        if not usuario:
            return None, 404
        return usuario, 200

    def atualizar(self, tipo, usuario_id, info):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status

        novo_email = info.get('email', usuario.email)
        novo_cpf = info.get('cpf', usuario.cpf)
        if self.repository.email_ou_cpf_existe(novo_email, novo_cpf, usuario_id=usuario.id):
            return None, 409

        _aplicar_dados(usuario, info)
        self.repository.salvar()
        return usuario, 200

    def deletar(self, tipo, usuario_id):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status

        self.repository.deletar(usuario)
        return None, 204

    def registrar(self, info):
        return self.criar(info)


def registroPadrao(info):
    usuario, status = UserService().criar(info)
    return status if status != 201 else usuario
