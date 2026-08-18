from flask import jsonify, request

from services.sinal_vital_service import SinalVitalService


sinal_vital_service = SinalVitalService()


def criar_sinal_vital():
    sinal_vital, status = sinal_vital_service.criar(request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Informe ao menos um sinal vital; data deve estar em ISO 8601"}), 400
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o sinal vital"}), 500
    return jsonify(sinal_vital.to_dict), 201
