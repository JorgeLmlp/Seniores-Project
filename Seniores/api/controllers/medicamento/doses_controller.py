from flask import g, request, jsonify
from services.medicamento import doses_service as service

def _resposta(resultado):
    corpo, status = resultado if isinstance(resultado, tuple) else (resultado, 200)
    return ("", 204) if status == 204 else (jsonify(corpo), status)

def alertas_medicamentos(paciente_id):
    return _resposta(service.alertas_medicamentos(paciente_id, g.get('usuario'), request.method, request.get_json(silent=True) or {}))

def doses(medicamento_id, dia):
    return _resposta(service.doses(medicamento_id, dia, g.get('usuario'), request.method, request.get_json(silent=True) or {}))
