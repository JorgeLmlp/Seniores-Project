"""Consultas de doses, vínculos e solicitações de cuidado."""
import re
from extensions import db
from models.medicamento.remedio import Remedio
from models.medicamento.dose import Dose
from models.paciente.paciente import Paciente
from models.paciente.cuidados import AdministracaoMedicamento
from models.relacionamento.solicitacao import Solicitacao

def buscar(modelo, chave):
    return db.session.get(modelo, chave)

def medicamentos(paciente_id):
    return db.session.scalars(db.select(Remedio).where(Remedio.paciente_id == paciente_id)).all()

def doses_do_dia(ids, dia):
    return db.session.scalars(db.select(Dose).where(Dose.medicamento_id.in_(ids), Dose.data == dia)).all() if ids else []

def administracao(paciente_id, medicamento_id, horario_previsto):
    return db.session.scalar(db.select(AdministracaoMedicamento).where(
        AdministracaoMedicamento.paciente_id == paciente_id,
        AdministracaoMedicamento.medicamento_id == medicamento_id,
        AdministracaoMedicamento.horario_previsto == horario_previsto,
    ).order_by(AdministracaoMedicamento.id.desc()))

def por_cpf(classe, cpf):
    numero = re.sub(r'\D', '', str(cpf or ''))
    if len(numero) != 11:
        return None
    normalizado = db.func.replace(db.func.replace(classe.cpf, '.', ''), '-', '')
    return db.session.scalar(db.select(classe).where(normalizado == numero))

def por_email(classe, email):
    normalizado = str(email or '').strip().lower()
    if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', normalizado):
        return None
    return db.session.scalar(db.select(classe).where(db.func.lower(classe.email) == normalizado))

def pacientes_do_usuario(usuario, tipo):
    campo = Paciente.responsavel_id if tipo == 'responsavel' else Paciente.cuidador_id
    return db.session.scalars(db.select(Paciente).where(campo == usuario.id)).all()

def solicitacoes_do_usuario(usuario):
    campo = Solicitacao.responsavel_id if usuario.tipo == 'responsavel' else Solicitacao.cuidador_id
    return db.session.scalars(db.select(Solicitacao).where(campo == usuario.id).order_by(Solicitacao.id.desc())).all()

def solicitacao_pendente(paciente_id, cuidador_id, responsavel_id):
    return db.session.scalar(db.select(Solicitacao).where(
        Solicitacao.paciente_id == paciente_id, Solicitacao.cuidador_id == cuidador_id,
        Solicitacao.responsavel_id == responsavel_id, Solicitacao.status == 'pendente'))

def possui_dependencias(usuario):
    for tabela in db.metadata.tables.values():
        for coluna in tabela.columns:
            if any(fk.column.table.name == usuario.__tablename__ and fk.column.name == 'id' for fk in coluna.foreign_keys):
                if db.session.execute(db.select(coluna).where(coluna == usuario.id).limit(1)).first() is not None:
                    return True
    return False
