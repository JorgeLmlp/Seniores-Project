from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


CLASSES_POR_TIPO = {
    "cuidador": Cuidador,
    "paciente": Paciente,
    "responsavel": Responsavel,
}


def classe_por_tipo(tipo):
    return CLASSES_POR_TIPO.get((tipo or "").lower())


def classes_de_usuario():
    return CLASSES_POR_TIPO.values()


def email_ou_cpf_existe(classe, email, cpf, usuario_id=None):
    return classe.email_ou_cpf_existe(
        CLASSES_POR_TIPO.values(), email, cpf, usuario_id
    )


def criar(classe, dados):
    return classe.criar(dados)


def listar(classe):
    return classe.listar()


def listar_todos():
    usuarios = []
    for classe in CLASSES_POR_TIPO.values():
        usuarios.extend(classe.listar())
    return usuarios


def listar_pacientes_por_cuidador(cuidador_id):
    return Paciente.listar_por_cuidador(cuidador_id)


def buscar_por_id(classe, usuario_id):
    return classe.buscar_por_id(usuario_id)


def atualizar(usuario, dados):
    return usuario.atualizar(dados)


def deletar(usuario):
    return usuario.deletar()
