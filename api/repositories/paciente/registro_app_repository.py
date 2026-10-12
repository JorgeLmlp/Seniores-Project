from extensions import db
from models.paciente.paciente import Paciente
from models.paciente.registro_app import RegistroApp


def buscar_paciente(paciente_id):
    return db.session.get(Paciente, paciente_id)


def criar(paciente_id, recurso, dados):
    return RegistroApp(
        paciente_id=paciente_id, recurso=recurso, dados=dados
    ).salvar()


def listar(paciente_id, recurso):
    consulta = (
        db.select(RegistroApp)
        .where(
            RegistroApp.paciente_id == paciente_id,
            RegistroApp.recurso == recurso,
        )
        .order_by(RegistroApp.data_criacao.desc())
    )
    return db.session.scalars(consulta).all()


def buscar(registro_id):
    return db.session.get(RegistroApp, registro_id)


def salvar(registro):
    return registro.salvar()


def deletar(registro):
    return registro.deletar()
