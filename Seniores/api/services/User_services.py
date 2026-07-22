from extensions import db
from werkzeug.security import generate_password_hash
from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


CLASSES_POR_TIPO = {
    # Toda entrada de tipo aceita pela API precisa apontar para um model valido.
    'cuidador': Cuidador,
    'paciente': Paciente,
    'responsavel': Responsavel,
}
def _aplicar_dados(usuario, info):
    """Aplica apenas os campos enviados em uma atualizacao parcial.

    Os pares em portugues/ingles mantem compatibilidade com clientes antigos.
    """
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
    """Regras de cadastro, consulta, alteracao e exclusao de usuarios."""

    def _normalizar_tipo(self, tipo):
        """Evita que maiusculas e minusculas mudem o tipo do usuario."""
        return (tipo or '').lower()

    def _classe_por_tipo(self, tipo):
        """Converte o texto do request para a classe SQLAlchemy correspondente."""
        return CLASSES_POR_TIPO.get(self._normalizar_tipo(tipo))

    def _email_ou_cpf_existe(self, email, cpf, usuario_id=None, tipo_atual=None):
        """Verifica duplicidade nas tres tabelas de usuario.

        Em uma edicao, ignora o proprio registro para nao acusar duplicidade falsa.
        """
        tipo_normalizado = self._normalizar_tipo(tipo_atual) if tipo_atual else None

        for tipo_chave, modelo in CLASSES_POR_TIPO.items():
            query = modelo.query.filter((modelo.email == email) | (modelo.cpf == cpf))
            if usuario_id is not None and tipo_chave == tipo_normalizado:
                query = query.filter(modelo.id != usuario_id)
            if query.first():
                return True
        return False

    def criar(self, info):
        """Valida os dados, cria a subclasse correta e guarda a senha em hash."""
        nome = info.get('nome') or info.get('name')
        email = info.get('email')
        senha = info.get('senha') or info.get('password')
        telefone = info.get('telefone') or info.get('phoneNumber')
        cpf = info.get('cpf')
        tipo = info.get('tipo')
        classe = self._classe_por_tipo(tipo)

        if not all([nome, email, senha, telefone, cpf, classe]):
            return None, 400

        if self._email_ou_cpf_existe(email, cpf):
            return None, 409

        usuario = classe(
            name=nome,
            email=email,
            # A senha nunca e persistida em texto puro.
            password=generate_password_hash(senha),
            phoneNumber=telefone,
            cpf=cpf,
            tipo=self._normalizar_tipo(tipo),
        )
        db.session.add(usuario)
        db.session.commit()

        return usuario, 201

    def listar(self, tipo=None):
        """Lista um tipo especifico ou combina os tres tipos quando omitido."""
        if tipo:
            classe = self._classe_por_tipo(tipo)
            if not classe:
                return None, 400
            return classe.query.all(), 200

        usuarios = []
        for classe in CLASSES_POR_TIPO.values():
            usuarios.extend(classe.query.all())
        return usuarios, 200

    def buscar_por_id(self, tipo, usuario_id):
        """Busca na tabela indicada, pois IDs podem se repetir entre tabelas."""
        classe = self._classe_por_tipo(tipo)
        if not classe:
            return None, 400

        usuario = classe.query.get(usuario_id)
        if not usuario:
            return None, 404
        return usuario, 200

    def atualizar(self, tipo, usuario_id, info):
        """Atualiza campos enviados e protege email/CPF contra duplicacao."""
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status

        novo_email = info.get('email', usuario.email)
        novo_cpf = info.get('cpf', usuario.cpf)
        if self._email_ou_cpf_existe(
            novo_email, novo_cpf, usuario_id=usuario.id, tipo_atual=tipo
        ):
            return None, 409

        _aplicar_dados(usuario, info)
        db.session.commit()
        return usuario, 200

    def deletar(self, tipo, usuario_id):
        """Remove o usuario encontrado e confirma a exclusao."""
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status

        db.session.delete(usuario)
        db.session.commit()
        return None, 204

    def registrar(self, info):
        """Alias mantido para chamadas antigas que usam o nome registrar."""
        return self.criar(info)


def registroPadrao(info):
    """Atalho legado para cadastrar um usuario fora do controller."""
    return UserService().criar(info)
