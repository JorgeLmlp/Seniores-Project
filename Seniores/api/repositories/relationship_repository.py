from extensions import db
from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


MODELOS_POR_TIPO = {
    # Centraliza a traducao do tipo recebido pela API para sua tabela.
    "paciente": Paciente,
    "responsavel": Responsavel,
    "cuidador": Cuidador,
}


def pesquisar_por_cpf(tipo, cpf):
    """Localiza um usuario de um tipo especifico pelo CPF."""
    modelo = MODELOS_POR_TIPO.get((tipo or "").lower())
    if not modelo:
        return None
    return db.session.scalar(db.select(modelo).where(modelo.cpf == cpf))
