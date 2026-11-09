from models.relacionamento.solicitacao import Solicitacao
from models import transacao
from repositories import fluxo_repository as repo
from models.paciente.paciente import Paciente
from models.cuidador.cuidador import Cuidador
from models.relacionamento.paciente_responsavel import Paciente_responsavel
from models.relacionamento.cuidador_responsavel import CuidadorResponsavel


def meus_pacientes(usuario_atual, metodo, dados):
    u = usuario_atual
    if u.tipo == 'paciente':
        pacientes = [u]
    elif u.tipo == 'responsavel':
        pacientes = repo.pacientes_do_usuario(u, 'responsavel')
    else:
        pacientes = repo.pacientes_do_usuario(u, 'cuidador')
    return [p.to_dict for p in pacientes]


def vincular_paciente(usuario_atual, metodo, dados):
    if usuario_atual.tipo != 'responsavel':
        return ({'erro': 'Somente o responsável pode vincular pacientes.'}, 403)
    p = repo.por_cpf(Paciente, dados.get('cpf'))
    if not p:
        return ({'erro': 'Paciente não encontrado pelo CPF.'}, 404)
    if p.responsavel_id not in (None, usuario_atual.id):
        return ({'erro': 'Paciente já vinculado a outro responsável.'}, 409)
    p.responsavel_id = usuario_atual.id
    if not repo.buscar(Paciente_responsavel, (p.id, usuario_atual.id)):
        transacao.adicionar(Paciente_responsavel(paciente_id=p.id, responsavel_id=usuario_atual.id))
    transacao.confirmar()
    return (p.to_dict, 200)


def solicitacoes(usuario_atual, metodo, dados):
    u = usuario_atual
    if u.tipo not in ('responsavel', 'cuidador'):
        return ({'erro': 'Perfil sem acesso às solicitações.'}, 403)
    if metodo == 'GET':
        return [s.json() for s in repo.solicitacoes_do_usuario(u)]
    if u.tipo != 'responsavel':
        return ({'erro': 'Somente o responsável pode solicitar vínculo.'}, 403)
    p = repo.buscar(Paciente, dados.get('paciente_id')) if isinstance(dados.get('paciente_id'), int) else None
    if not p or p.responsavel_id != u.id:
        return ({'erro': 'Selecione um paciente vinculado à sua conta.'}, 403)
    c = repo.por_email(Cuidador, dados.get('email'))
    if not c:
        return ({'erro': 'Cuidador não encontrado pelo e-mail.'}, 404)
    existente = repo.solicitacao_pendente(p.id, c.id, u.id)
    if existente or p.cuidador_id == c.id:
        return ({'erro': 'Já existe um vínculo ou solicitação pendente.'}, 409)
    s = Solicitacao(paciente_id=p.id, cuidador_id=c.id, responsavel_id=u.id)
    transacao.adicionar(s)
    transacao.confirmar()
    return (s.json(), 201)


def responder(id, usuario_atual, metodo, dados):
    s = repo.buscar(Solicitacao, id)
    if usuario_atual.tipo != 'cuidador' or not s or s.cuidador_id != usuario_atual.id:
        return ({'erro': 'Solicitação não disponível para sua conta.'}, 403)
    status = dados.get('status')
    if status not in ('aceita', 'recusada'):
        return ({'erro': 'Escolha aceitar ou recusar.'}, 400)
    if s.status != 'pendente':
        return ({'erro': 'Solicitação já respondida.'}, 409)
    p = repo.buscar(Paciente, s.paciente_id)
    if not p or p.responsavel_id != s.responsavel_id:
        return ({'erro': 'Vínculo do responsável alterado.'}, 409)
    if status == 'aceita':
        if p.cuidador_id not in (None, s.cuidador_id):
            return ({'erro': 'Paciente já possui outro cuidador.'}, 409)
        p.cuidador_id = s.cuidador_id
        if not repo.buscar(CuidadorResponsavel, (s.cuidador_id, s.responsavel_id)):
            transacao.adicionar(CuidadorResponsavel(cuidador_id=s.cuidador_id, responsavel_id=s.responsavel_id))
    s.status = status
    transacao.confirmar()
    return s.json()


def minha_conta(usuario_atual, metodo, dados):
    if metodo == 'GET':
        return usuario_atual.to_dict
    from services.usuario.usuario_service import UsuarioService
    permitidos = {'nome', 'email', 'telefone', 'senha', 'cpf'}
    if usuario_atual.tipo == 'paciente':
        permitidos |= {'idade', 'tipo_sanguineo', 'preferencias'}
    dados = {k: v.strip() if isinstance(v, str) else v for k, v in dados.items() if k in permitidos}
    if not dados or any((not isinstance(v, str) or not v for k, v in dados.items() if k in {'nome', 'email', 'telefone', 'senha', 'cpf'})):
        return ({'erro': 'Preencha os campos corretamente.'}, 400)
    usuario, status = UsuarioService().atualizar(usuario_atual.tipo, usuario_atual.id, dados)
    if status != 200:
        return ({'erro': 'Não foi possível atualizar. Confira os dados e o e-mail.'}, status)
    return usuario.to_dict


def excluir_minha_conta(usuario_atual, metodo, dados):
    """Deletes only an unlinked, empty account after password verification.

    A linked patient or clinical record requires an explicit data-retention/
    transfer process; we intentionally refuse destructive cascade deletion.
    """
    usuario = usuario_atual
    senha = dados.get('senha')
    if not isinstance(senha, str) or not usuario.senha_confere(senha):
        return ({'erro': 'Senha incorreta.'}, 403)
    if repo.possui_dependencias(usuario):
        return ({'erro': 'A conta possui vínculos ou registros dependentes. Solicite a desvinculação e a destinação dos dados antes de excluir.'}, 409)
    if not usuario.deletar():
        return ({'erro': 'Não foi possível excluir a conta.'}, 500)
    return ('', 204)
