import re
from datetime import datetime
from flask import Blueprint, g, request, jsonify
from extensions import db
from models.paciente.paciente import Paciente
from models.cuidador.cuidador import Cuidador
from models.responsavel.responsavel import Responsavel
from models.relacionamento.paciente_responsavel import Paciente_responsavel
from models.relacionamento.cuidador_responsavel import CuidadorResponsavel

solicitacoesbp = Blueprint('solicitacoes', __name__)


class Solicitacao(db.Model):
    __tablename__ = 'solicitacoes_cuidado'
    id = db.Column(db.Integer, primary_key=True)
    responsavel_id = db.Column(db.Integer, db.ForeignKey('responsaveis.id'), nullable=False)
    cuidador_id = db.Column(db.Integer, db.ForeignKey('cuidadores.id'), nullable=False)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    status = db.Column(db.String(15), nullable=False, default='pendente')
    criada_em = db.Column(db.DateTime, default=datetime.now)

    def json(self):
        def resumo(classe, id):
            pessoa = db.session.get(classe, id)
            return {
                'id': pessoa.id,
                'nome': pessoa.name,
                'telefone': pessoa.phoneNumber,
                'email': pessoa.email,
            } if pessoa else None
        return {'id': self.id, 'status': self.status,
                'responsavel': resumo(Responsavel, self.responsavel_id),
                'paciente': resumo(Paciente, self.paciente_id),
                'cuidador': resumo(Cuidador, self.cuidador_id)}


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
    return db.session.scalar(
        db.select(classe).where(db.func.lower(classe.email) == normalizado)
    )


@solicitacoesbp.get('/minha-conta/pacientes')
def meus_pacientes():
    u = g.usuario
    if u.tipo == 'paciente':
        pacientes = [u]
    elif u.tipo == 'responsavel':
        pacientes = db.session.scalars(db.select(Paciente).where(Paciente.responsavel_id == u.id)).all()
    else:
        pacientes = db.session.scalars(db.select(Paciente).where(Paciente.cuidador_id == u.id)).all()
    return jsonify([p.to_dict for p in pacientes])


@solicitacoesbp.post('/minha-conta/pacientes')
def vincular_paciente():
    if g.usuario.tipo != 'responsavel':
        return jsonify(erro='Somente o responsável pode vincular pacientes.'), 403
    p = por_cpf(Paciente, (request.get_json(silent=True) or {}).get('cpf'))
    if not p:
        return jsonify(erro='Paciente não encontrado pelo CPF.'), 404
    if p.responsavel_id not in (None, g.usuario.id):
        return jsonify(erro='Paciente já vinculado a outro responsável.'), 409
    p.responsavel_id = g.usuario.id
    if not db.session.get(Paciente_responsavel, (p.id, g.usuario.id)):
        db.session.add(Paciente_responsavel(paciente_id=p.id, responsavel_id=g.usuario.id))
    db.session.commit()
    return jsonify(p.to_dict), 200


@solicitacoesbp.route('/minha-conta/solicitacoes', methods=['GET', 'POST'])
def solicitacoes():
    u = g.usuario
    if u.tipo not in ('responsavel', 'cuidador'):
        return jsonify(erro='Perfil sem acesso às solicitações.'), 403
    if request.method == 'GET':
        filtro = Solicitacao.responsavel_id == u.id if u.tipo == 'responsavel' else Solicitacao.cuidador_id == u.id
        return jsonify([s.json() for s in db.session.scalars(db.select(Solicitacao).where(filtro).order_by(Solicitacao.id.desc()))])
    if u.tipo != 'responsavel':
        return jsonify(erro='Somente o responsável pode solicitar vínculo.'), 403
    dados = request.get_json(silent=True) or {}
    p = db.session.get(Paciente, dados.get('paciente_id')) if isinstance(dados.get('paciente_id'), int) else None
    if not p or p.responsavel_id != u.id:
        return jsonify(erro='Selecione um paciente vinculado à sua conta.'), 403
    c = por_email(Cuidador, dados.get('email'))
    if not c:
        return jsonify(erro='Cuidador não encontrado pelo e-mail.'), 404
    existente = db.session.scalar(db.select(Solicitacao).where(
        Solicitacao.paciente_id == p.id, Solicitacao.cuidador_id == c.id,
        Solicitacao.responsavel_id == u.id, Solicitacao.status == 'pendente'))
    if existente or p.cuidador_id == c.id:
        return jsonify(erro='Já existe um vínculo ou solicitação pendente.'), 409
    s = Solicitacao(paciente_id=p.id, cuidador_id=c.id, responsavel_id=u.id)
    db.session.add(s)
    db.session.commit()
    return jsonify(s.json()), 201


@solicitacoesbp.patch('/minha-conta/solicitacoes/<int:id>')
def responder(id):
    s = db.session.get(Solicitacao, id)
    if g.usuario.tipo != 'cuidador' or not s or s.cuidador_id != g.usuario.id:
        return jsonify(erro='Solicitação não disponível para sua conta.'), 403
    status = (request.get_json(silent=True) or {}).get('status')
    if status not in ('aceita', 'recusada'):
        return jsonify(erro='Escolha aceitar ou recusar.'), 400
    if s.status != 'pendente':
        return jsonify(erro='Solicitação já respondida.'), 409
    p = db.session.get(Paciente, s.paciente_id)
    if not p or p.responsavel_id != s.responsavel_id:
        return jsonify(erro='Vínculo do responsável alterado.'), 409
    if status == 'aceita':
        if p.cuidador_id not in (None, s.cuidador_id):
            return jsonify(erro='Paciente já possui outro cuidador.'), 409
        p.cuidador_id = s.cuidador_id
        if not db.session.get(CuidadorResponsavel, (s.cuidador_id, s.responsavel_id)):
            db.session.add(CuidadorResponsavel(cuidador_id=s.cuidador_id, responsavel_id=s.responsavel_id))
    s.status = status
    db.session.commit()
    return jsonify(s.json())


@solicitacoesbp.route('/minha-conta', methods=['GET', 'PATCH'])
def minha_conta():
    if request.method == 'GET':
        return jsonify(g.usuario.to_dict)
    from services.usuario.usuario_service import UsuarioService
    dados = request.get_json(silent=True) or {}
    permitidos = {'nome', 'email', 'telefone', 'senha', 'cpf'}
    if g.usuario.tipo == 'paciente':
        permitidos |= {'idade', 'tipo_sanguineo', 'preferencias'}
    dados = {k: v.strip() if isinstance(v, str) else v for k, v in dados.items() if k in permitidos}
    if not dados or any((not isinstance(v, str) or not v) for k, v in dados.items() if k in {'nome', 'email', 'telefone', 'senha', 'cpf'}):
        return jsonify(erro='Preencha os campos corretamente.'), 400
    usuario, status = UsuarioService().atualizar(g.usuario.tipo, g.usuario.id, dados)
    if status != 200:
        return jsonify(erro='Não foi possível atualizar. Confira os dados e o e-mail.'), status
    return jsonify(usuario.to_dict)


@solicitacoesbp.delete('/minha-conta')
def excluir_minha_conta():
    """Deletes only an unlinked, empty account after password verification.

    A linked patient or clinical record requires an explicit data-retention/
    transfer process; we intentionally refuse destructive cascade deletion.
    """
    usuario = g.usuario
    dados = request.get_json(silent=True) or {}
    senha = dados.get('senha')
    if not isinstance(senha, str) or not usuario.senha_confere(senha):
        return jsonify(erro='Senha incorreta.'), 403

    # Check all declared FKs referencing the authenticated user's typed table.
    # This also catches medications, diaries, caregiver/patient links and invites.
    from sqlalchemy import select
    for tabela in db.metadata.tables.values():
        for coluna in tabela.columns:
            if any(fk.column.table.name == usuario.__tablename__ and
                   fk.column.name == 'id' for fk in coluna.foreign_keys):
                existe = db.session.execute(select(coluna).where(coluna == usuario.id).limit(1)).first()
                if existe is not None:
                    return jsonify(erro='A conta possui vínculos ou registros dependentes. '
                                         'Solicite a desvinculação e a destinação dos dados antes de excluir.'), 409
    if not usuario.deletar():
        return jsonify(erro='Não foi possível excluir a conta.'), 500
    return '', 204
