from flask import g, request, jsonify
from services.relacionamento import solicitacoes_service as service

def _resposta(resultado):
    corpo, status = resultado if isinstance(resultado, tuple) else (resultado, 200)
    return ("", 204) if status == 204 else (jsonify(corpo), status)

def meus_pacientes():
    return _resposta(service.meus_pacientes(g.get('usuario'), request.method, request.get_json(silent=True) or {}))

def vincular_paciente():
    return _resposta(service.vincular_paciente(g.get('usuario'), request.method, request.get_json(silent=True) or {}))

def solicitacoes():
    return _resposta(service.solicitacoes(g.get('usuario'), request.method, request.get_json(silent=True) or {}))

def responder(id):
    return _resposta(service.responder(id, g.get('usuario'), request.method, request.get_json(silent=True) or {}))

def minha_conta():
    return _resposta(service.minha_conta(g.get('usuario'), request.method, request.get_json(silent=True) or {}))

def excluir_minha_conta():
    return _resposta(service.excluir_minha_conta(g.get('usuario'), request.method, request.get_json(silent=True) or {}))
