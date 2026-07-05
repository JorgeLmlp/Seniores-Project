from extensions import db
from models.cuidador import Cuidador
from models.paciente import Paciente
from models.responsavel import Responsavel


CLASSES_POR_TIPO = {
    'cuidador': Cuidador,
    'paciente': Paciente,
    'responsavel': Responsavel,
}


class UserRepository: #classe que controla as consultas e alteraçoes no banco de dados
    def normalizar_tipo(self, tipo):
        return (tipo or '').lower()

    def classe_por_tipo(self, tipo):
        return CLASSES_POR_TIPO.get(self.normalizar_tipo(tipo))

    def email_ou_cpf_existe(self, email, cpf, usuario_id=None):
        for modelo in CLASSES_POR_TIPO.values():
            query = modelo.query.filter((modelo.email == email) | (modelo.cpf == cpf))
            if usuario_id is not None:
                query = query.filter(modelo.id != usuario_id)
            if query.first():
                return True
        return False

    def criar_usuario(self, tipo, nome, email, senha, telefone, cpf):
        classe = self.classe_por_tipo(tipo)
        if not classe:
            return None

        usuario = classe(
            name=nome,
            email=email,
            password=senha,
            phoneNumber=telefone,
            cpf=cpf,
            tipo=self.normalizar_tipo(tipo),
        )

        db.session.add(usuario)
        db.session.commit()
        return usuario

    def listar(self, tipo=None):
        if tipo:
            classe = self.classe_por_tipo(tipo)
            if not classe:
                return None
            return classe.query.all()

        usuarios = []
        for classe in CLASSES_POR_TIPO.values():
            usuarios.extend(classe.query.all())
        return usuarios

    def buscar_por_id(self, tipo, usuario_id):
        classe = self.classe_por_tipo(tipo)
        if not classe:
            return None
        return classe.query.get(usuario_id)

    def salvar(self):
        db.session.commit()

    def deletar(self, usuario):
        db.session.delete(usuario)
        db.session.commit()
