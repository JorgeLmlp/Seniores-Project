"""Consultas de usuarios, centralizadas por tipo concreto de perfil."""

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
    """Traduz o tipo publico da API para o model correspondente."""
    return CLASSES_POR_TIPO.get((tipo or "").lower())


def buscar_por_id(classe, usuario_id):
    """Busca um usuario na tabela representada por ``classe``."""
    return db.session.get(classe, usuario_id)


def buscar_por_cpf(classe, cpf):
    """Busca CPF dentro de uma categoria de usuario."""
    return db.session.scalar(db.select(classe).where(classe.cpf == cpf))


def buscar_por_email(classe, email):
    """Busca e-mail dentro de uma categoria de usuario."""
    return db.session.scalar(db.select(classe).where(classe.email == email))


def listar(classe):
    """Lista todos os usuarios de uma categoria."""
    return db.session.scalars(db.select(classe)).all()


def listar_todos():
    """Combina as tres tabelas concretas em uma unica lista."""
    usuarios = []
    for classe in CLASSES_POR_TIPO.values():
        usuarios.extend(listar(classe))
    return usuarios


def listar_pacientes_por_cuidador(cuidador_id):
    """Lista os pacientes diretamente vinculados ao cuidador."""
    return db.session.scalars(
        db.select(Paciente)
        .where(Paciente.cuidador_id == cuidador_id)
        .order_by(Paciente.name)
    ).all()


def email_ou_cpf_existe(email, cpf, classe_atual=None, usuario_id=None):
    """Detecta duplicidade, ignorando o proprio registro em atualizacoes."""
    for classe in CLASSES_POR_TIPO.values():
        consulta = db.select(classe).where((classe.email == email) | (classe.cpf == cpf))
        if classe is classe_atual and usuario_id is not None:
            consulta = consulta.where(classe.id != usuario_id)
        if db.session.scalar(consulta):
            return True
    return False
