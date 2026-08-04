from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


CLASSES_POR_TIPO = {
    "cuidador": Cuidador,
    "paciente": Paciente,
    "responsavel": Responsavel,
}


class UserService:
    """Valida requisicoes e delega todo CRUD aos models de usuario."""

    @staticmethod
    def _normalizar_tipo(tipo):
        return (tipo or "").lower()

    def _classe_por_tipo(self, tipo):
        return CLASSES_POR_TIPO.get(self._normalizar_tipo(tipo))

    def criar(self, info):
        nome = info.get("nome") or info.get("name")
        dados = {
            "nome": nome,
            "email": info.get("email"),
            "senha": info.get("senha") or info.get("password"),
            "telefone": info.get("telefone") or info.get("phoneNumber"),
            "cpf": info.get("cpf"),
            "tipo": self._normalizar_tipo(info.get("tipo")),
        }
        classe = self._classe_por_tipo(dados["tipo"])
        if not all([*dados.values(), classe]):
            return None, 400
        if classe.email_ou_cpf_existe(CLASSES_POR_TIPO.values(), dados["email"], dados["cpf"]):
            return None, 409
        usuario = classe.criar(dados)
        return (usuario, 201) if usuario else (None, 500)

    def listar(self, tipo=None, cuidador_id=None):
        """Lista usuarios, com suporte aos pacientes de um cuidador especifico."""
        if cuidador_id is not None:
            if self._normalizar_tipo(tipo) != "paciente":
                return None, 400
            try:
                cuidador_id = int(cuidador_id)
            except (TypeError, ValueError):
                return None, 400
            return Paciente.listar_por_cuidador(cuidador_id), 200
        if tipo:
            classe = self._classe_por_tipo(tipo)
            return (classe.listar(), 200) if classe else (None, 400)
        usuarios = []
        for classe in CLASSES_POR_TIPO.values():
            usuarios.extend(classe.listar())
        return usuarios, 200

    def buscar_por_id(self, tipo, usuario_id):
        classe = self._classe_por_tipo(tipo)
        if not classe:
            return None, 400
        usuario = classe.buscar_por_id(usuario_id)
        return (usuario, 200) if usuario else (None, 404)

    def login(self, info):
        """Autentica pelo e-mail e pela senha usando o hash salvo no model."""
        email = info.get("email")
        senha = info.get("senha") or info.get("password")
        if not email or not senha:
            return None, 400

        tipo = info.get("tipo")
        if tipo:
            classes = [self._classe_por_tipo(tipo)]
            if classes[0] is None:
                return None, 400
        else:
            classes = CLASSES_POR_TIPO.values()

        usuario = None
        for classe in classes:
            usuario = classe.buscar_por_email(email)
            if usuario:
                break
        if not usuario or not usuario.senha_confere(senha):
            return None, 401
        return usuario, 200

    def atualizar(self, tipo, usuario_id, info):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status
        novo_email = info.get("email", usuario.email)
        novo_cpf = info.get("cpf", usuario.cpf)
        if usuario.email_ou_cpf_existe(
            CLASSES_POR_TIPO.values(), novo_email, novo_cpf, usuario.id
        ):
            return None, 409
        usuario = usuario.atualizar(info)
        return (usuario, 200) if usuario else (None, 500)

    def deletar(self, tipo, usuario_id):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status
        return (None, 204) if usuario.deletar() else (None, 500)

    def registrar(self, info):
        return self.criar(info)


def registroPadrao(info):
    return UserService().criar(info)
