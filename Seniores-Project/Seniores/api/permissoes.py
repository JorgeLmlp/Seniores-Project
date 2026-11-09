"""Permissões efetivas de escrita nos registros de um paciente."""

from extensions import db
from models.paciente.cuidados import PermissaoMembro


def pode_escrever(paciente_id, tipo, membro_id):
    if tipo == 'responsavel':
        return True
    permissao = db.session.scalar(db.select(PermissaoMembro).where(
        PermissaoMembro.paciente_id == paciente_id,
        PermissaoMembro.membro_tipo == tipo,
        PermissaoMembro.membro_id == membro_id,
    ).order_by(PermissaoMembro.id.desc()))
    if permissao:
        return permissao.nivel == 'escrita'
    return tipo == 'paciente'
