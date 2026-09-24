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


def vincular_paciente_responsavel(paciente, responsavel):
    from models.relacionamento.paciente_responsavel import Paciente_responsavel

    return Paciente_responsavel.criar_ou_atualizar(paciente, responsavel)


def vincular_paciente_cuidador(paciente, cuidador):
    return paciente.vincular_cuidador(cuidador)


def vincular_cuidador_responsavel(cuidador, responsavel):
    from models.relacionamento.cuidador_responsavel import CuidadorResponsavel

    return CuidadorResponsavel.criar_ou_buscar(cuidador, responsavel)
