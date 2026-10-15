from extensions import db
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


def buscar_por_id(classe, usuario_id):
    return db.session.get(classe, usuario_id)


def buscar_por_cpf(classe, cpf):
    return db.session.scalar(db.select(classe).where(classe.cpf == cpf))


def buscar_por_email(classe, email):
    return db.session.scalar(db.select(classe).where(classe.email == email))


def listar(classe):
    return db.session.scalars(db.select(classe)).all()


def listar_todos():
    usuarios = []
    for classe in CLASSES_POR_TIPO.values():
        usuarios.extend(listar(classe))
    return usuarios


def listar_pacientes_por_cuidador(cuidador_id):
    return db.session.scalars(
        db.select(Paciente)
        .where(Paciente.cuidador_id == cuidador_id)
        .order_by(Paciente.name)
    ).all()


def email_ou_cpf_existe(email, cpf, classe_atual=None, usuario_id=None):
    for classe in CLASSES_POR_TIPO.values():
        consulta = db.select(classe).where((classe.email == email) | (classe.cpf == cpf))
        if classe is classe_atual and usuario_id is not None:
            consulta = consulta.where(classe.id != usuario_id)
        if db.session.scalar(consulta):
            return True
    return False
