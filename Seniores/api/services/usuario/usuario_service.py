from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel
from repositories import usuario_repository


CLASSES_POR_TIPO = {
    "cuidador": Cuidador,
    "paciente": Paciente,
    "responsavel": Responsavel,
}


class UsuarioService:
    """Valida requisicoes e delega todo CRUD aos models de usuario."""

    @staticmethod
    def _normalizar_tipo(tipo):
        return (tipo or "").lower()

    def _classe_por_tipo(self, tipo):
        return usuario_repository.classe_por_tipo(self._normalizar_tipo(tipo))

    def criar(self, info):
        nome = info.get("nome") or info.get("name")
        dados = {
            "nome": nome,
            "email": info.get("email"),
            "senha": info.get("senha") or info.get("password"),
            "telefone": info.get("telefone") or info.get("phoneNumber"),
            "cpf": info.get("cpf"),
            "tipo": self._normalizar_tipo(info.get("tipo")),
            "idade": info.get("idade"),
            "tipo_sanguineo": info.get("tipo_sanguineo") or info.get("tipoSanguineo"),
            "preferencias": info.get("preferencias"),
        }
        classe = self._classe_por_tipo(dados["tipo"])
        obrigatorios = (dados["nome"], dados["email"], dados["senha"], dados["telefone"], dados["cpf"])
        if not classe or not all(obrigatorios):
            return None, 400
        if classe is Paciente and not self._perfil_paciente_valido(dados, parcial=True):
            return None, 400
        if usuario_repository.email_ou_cpf_existe(dados["email"], dados["cpf"]):
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
            return usuario_repository.listar_pacientes_por_cuidador(cuidador_id), 200
        if tipo:
            classe = self._classe_por_tipo(tipo)
            return (
                usuario_repository.listar(classe), 200
            ) if classe else (None, 400)
        return usuario_repository.listar_todos(), 200

    def buscar_por_id(self, tipo, usuario_id):
        classe = self._classe_por_tipo(tipo)
        if not classe:
            return None, 400
        usuario = usuario_repository.buscar_por_id(classe, usuario_id)
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
        classes = [self._classe_por_tipo(tipo)] if tipo else CLASSES_POR_TIPO.values()
        usuario = None
        for classe in classes:
            if classe:
                usuario = usuario_repository.buscar_por_email(classe, email)
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
        if usuario_repository.email_ou_cpf_existe(
            novo_email, novo_cpf, usuario.__class__, usuario.id
        ):
            return None, 409
        if isinstance(usuario, Paciente) and not self._perfil_paciente_valido(info, parcial=True):
            return None, 400
        if isinstance(usuario, Paciente) and "tipoSanguineo" in info and "tipo_sanguineo" not in info:
            info = {**info, "tipo_sanguineo": info["tipoSanguineo"]}
        usuario = usuario.atualizar(info)
        return (usuario, 200) if usuario else (None, 500)

    def deletar(self, tipo, usuario_id):
        usuario, status = self.buscar_por_id(tipo, usuario_id)
        if status != 200:
            return None, status
        return (
            (None, 204)
            if usuario.deletar()
            else (None, 500)
        )

    def registrar(self, info):
        return self.criar(info)

    @staticmethod
    def _perfil_paciente_valido(dados, parcial=False):
        idade = dados.get("idade")
        if idade is not None and (not isinstance(idade, int) or isinstance(idade, bool) or not 0 <= idade <= 130):
            return False
        tipo = dados.get("tipo_sanguineo") or dados.get("tipoSanguineo")
        if tipo is not None and str(tipo).upper() not in {"A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"}:
            return False
        preferencias = dados.get("preferencias")
        if preferencias is not None and not isinstance(preferencias, dict):
            return False
        return True


def registroPadrao(info):
    return UsuarioService().criar(info)
