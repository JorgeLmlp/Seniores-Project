from repositories.usuario.login_repository import buscar_por_email
from repositories.usuario import user_repository


class UsuarioService:
    """Valida requisicoes e delega todo CRUD aos models de usuario."""

    @staticmethod
    def _normalizar_tipo(tipo):
        return (tipo or "").lower()

    def _classe_por_tipo(self, tipo):
        return user_repository.classe_por_tipo(self._normalizar_tipo(tipo))

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
        if user_repository.email_ou_cpf_existe(
            classe, dados["email"], dados["cpf"]
        ):
            return None, 409
        usuario = user_repository.criar(classe, dados)
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
            return user_repository.listar_pacientes_por_cuidador(
                cuidador_id
            ), 200
        if tipo:
            classe = self._classe_por_tipo(tipo)
            return (
                user_repository.listar(classe), 200
            ) if classe else (None, 400)
        return user_repository.listar_todos(), 200

    def buscar_por_id(self, tipo, usuario_id):
        classe = self._classe_por_tipo(tipo)
        if not classe:
            return None, 400
        usuario = user_repository.buscar_por_id(classe, usuario_id)
        return (usuario, 200) if usuario else (None, 404)

    def login(self, info):
        """Autentica pelo e-mail e pela senha usando o hash salvo no model."""
        email = info.get("email")
        senha = info.get("senha") or info.get("password")
        if not email or not senha:
            return None, 400

        tipo = info.get("tipo")
        if tipo and self._classe_por_tipo(tipo) is None:
            return None, 400
        usuario = buscar_por_email(email, tipo)
        if not usuario or not usuario.senha_confere(senha):
            return None, 401
        return usuario, 200

    def atualizar(self, tipo, usuario_id, info):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status
        novo_email = info.get("email", usuario.email)
        novo_cpf = info.get("cpf", usuario.cpf)
        if user_repository.email_ou_cpf_existe(
            usuario.__class__, novo_email, novo_cpf, usuario.id
        ):
            return None, 409
        usuario = user_repository.atualizar(usuario, info)
        return (usuario, 200) if usuario else (None, 500)

    def deletar(self, tipo, usuario_id):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status
        return (
            (None, 204)
            if user_repository.deletar(usuario)
            else (None, 500)
        )

    def registrar(self, info):
        return self.criar(info)


def registroPadrao(info):
    return UsuarioService().criar(info)
