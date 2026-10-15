from extensions import db
from models.relacionamento.cuidador_responsavel import CuidadorResponsavel
from models.relacionamento.paciente_responsavel import Paciente_responsavel


def buscar_paciente_responsavel(paciente_id, responsavel_id):
    return db.session.get(Paciente_responsavel, (paciente_id, responsavel_id))


def buscar_cuidador_responsavel(cuidador_id, responsavel_id):
    return db.session.get(CuidadorResponsavel, (cuidador_id, responsavel_id))
