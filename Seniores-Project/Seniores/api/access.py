"""Controle de acesso aos registros e bloqueio dos vínculos diretos antigos."""
import os
from flask import request, g, jsonify
from extensions import app, db
from auth import autenticado
from models.paciente.paciente import Paciente


@app.before_request
def proteger_registros():
    if request.method == 'OPTIONS' or not request.endpoint:
        return None
    if request.endpoint in ('users.login', 'users.criar_usuario'):
        return None
    if request.blueprint == 'solicitacoes':
        return None  # Estes endpoints possuem autenticação própria.
    # Compatibilidade dos testes históricos de services, executados isoladamente.
    if os.getenv('API_TESTING') == '1' and not request.headers.get('Authorization'):
        return None
    return autenticado(verificar_escopo)()


def verificar_escopo():
    if request.blueprint in ('registrar_relacionamento', 'registrar'):
        return jsonify(erro='Use Pacientes e vínculos para enviar uma solicitação.'), 403
    args = request.view_args or {}
    u = g.usuario
    if request.blueprint == 'users':
        if args.get('tipo') != u.tipo or args.get('usuario_id') != u.id:
            return jsonify(erro='Acesso permitido apenas à própria conta.'), 403
        return None
    paciente_id = args.get('paciente_id')
    if 'sinal_vital_id' in args:
        from models.paciente.sinal_vital import SinalVital
        sinal = db.session.get(SinalVital, args['sinal_vital_id'])
        paciente_id = sinal.paciente_id if sinal else None
    if 'medicamento_id' in args:
        from models.medicamento.remedio import Remedio
        registro = db.session.get(Remedio, args['medicamento_id'])
        paciente_id = registro.paciente_id if registro else None
    elif 'registro_id' in args:
        recurso = request.path.strip('/').split('/')[0]
        from services.paciente.paciente_registro_service import PacienteRegistroService
        from services.paciente.cuidados_service import CuidadosService
        from models.paciente.registro_app import RegistroApp
        from models.paciente.cuidados import ExameDocumento
        from models.paciente.sinal_vital import SinalVital
        modelo = PacienteRegistroService.RECURSOS.get(recurso, (None,))[0] or CuidadosService.CONFIG.get(recurso, (None,))[0]
        if not modelo:
            modelo = {'exames-documentos': ExameDocumento, 'sinais-vitais': SinalVital}.get(recurso, RegistroApp)
        registro = db.session.get(modelo, args['registro_id'])
        paciente_id = registro.paciente_id if registro else None
    if paciente_id is None:
        return jsonify(erro='Registro não encontrado ou acesso indisponível.'), 404
    p = db.session.get(Paciente, paciente_id)
    permitido = p and ((u.tipo == 'paciente' and p.id == u.id)
        or (u.tipo == 'responsavel' and p.responsavel_id == u.id)
        or (u.tipo == 'cuidador' and p.cuidador_id == u.id))
    if not permitido:
        return jsonify(erro='Paciente não vinculado à sua conta.'), 403
    if u.tipo != 'responsavel' and '/permissoes' in request.path and request.method != 'GET':
        return jsonify(erro='Somente o responsável pode alterar permissões.'), 403
    if request.method in ('POST', 'PUT', 'PATCH', 'DELETE') and u.tipo in ('paciente', 'cuidador'):
        from permissoes import pode_escrever

        if not pode_escrever(paciente_id, u.tipo, u.id):
            return jsonify(erro='Permissão de somente leitura para este paciente.'), 403
    return None
