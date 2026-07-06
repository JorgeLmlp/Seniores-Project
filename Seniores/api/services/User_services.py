from extensions import db
from werkzeug.security import generate_password_hash

from models.user import _aplicar_dados
from models.cuidador import Cuidador
from models.paciente import Paciente
from models.responsavel import Responsavel


CLASSES_POR_TIPO = {
    'cuidador': Cuidador,
    'paciente': Paciente,
    'responsavel': Responsavel,
}


class UserService:
    def _normalizar_tipo(self, tipo):
        return (tipo or '').lower()

    def _classe_por_tipo(self, tipo):
        return CLASSES_POR_TIPO.get(self._normalizar_tipo(tipo))

    def _email_ou_cpf_existe(self, email, cpf, usuario_id=None, tipo_atual=None):
        # tipo_atual identifica de qual classe é o usuario_id, para a
        # exclusão do próprio registro só valer dentro da mesma tabela.
        tipo_normalizado = self._normalizar_tipo(tipo_atual) if tipo_atual else None

        for tipo_chave, modelo in CLASSES_POR_TIPO.items():
            query = modelo.query.filter((modelo.email == email) | (modelo.cpf == cpf))
            if usuario_id is not None and tipo_chave == tipo_normalizado:
                query = query.filter(modelo.id != usuario_id)
            if query.first():
                return True
        return False

    def criar(self, info):
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
            password=generate_password_hash(senha),
            phoneNumber=telefone,
            cpf=cpf,
            tipo=self._normalizar_tipo(tipo),
        )
        db.session.add(usuario)
        db.session.commit()

        return usuario, 201

    def listar(self, tipo=None):
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
        classe = self._classe_por_tipo(tipo)
        if not classe:
            return None, 400

        usuario = classe.query.get(usuario_id)
        if not usuario:
            return None, 404
        return usuario, 200

    def atualizar(self, tipo, usuario_id, info):
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
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status

        db.session.delete(usuario)
        db.session.commit()
        return None, 204

    def registrar(self, info):
        return self.criar(info)


def registroPadrao(info):
    return UserService().criar(info)