from extensions import db
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


MODELOS_POR_TIPO = {
    "paciente": Paciente,
    "responsavel": Responsavel,
}


def pesquisar_por_cpf(tipo, cpf):
    modelo = MODELOS_POR_TIPO.get((tipo or "").lower())
    if not modelo:
        return None
    return db.session.scalar(db.select(modelo).where(modelo.cpf == cpf))
