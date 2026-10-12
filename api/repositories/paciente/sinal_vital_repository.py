from extensions import db
from models.paciente.paciente import Paciente
from models.paciente.sinal_vital import SinalVital


def buscar_paciente(paciente_id):
    return db.session.get(Paciente, paciente_id)


def criar(paciente_id, dados):
    return SinalVital.criar(paciente_id, dados)


def listar_por_paciente(paciente_id):
    consulta = (
        db.select(SinalVital)
        .where(SinalVital.paciente_id == paciente_id)
        .order_by(SinalVital.data.desc())
    )
    return db.session.scalars(consulta).all()


def buscar(sinal_vital_id):
    return db.session.get(SinalVital, sinal_vital_id)


def atualizar(sinal_vital, dados):
    return sinal_vital.atualizar(dados)


def deletar(sinal_vital):
    return sinal_vital.deletar()
