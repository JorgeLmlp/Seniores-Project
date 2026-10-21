from flask import jsonify, request

from services.paciente.sinal_vital_service import SinalVitalService


sinal_vital_service = SinalVitalService()


def criar_sinal_vital(paciente_id):
    sinal_vital, status = sinal_vital_service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Informe ao menos um sinal vital; data deve estar em ISO 8601"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o sinal vital"}), 500
    return jsonify(sinal_vital.to_dict), 201


def listar_sinais_vitais(paciente_id):
    sinais, status = sinal_vital_service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([sinal.to_dict for sinal in sinais]), 200


def buscar_sinal_vital(sinal_vital_id):
    sinal, status = sinal_vital_service.buscar(sinal_vital_id)
    if status == 404:
        return jsonify({"erro": "Sinal vital nao encontrado"}), 404
    return jsonify(sinal.to_dict), 200


def atualizar_sinal_vital(sinal_vital_id):
    sinal, status = sinal_vital_service.atualizar(sinal_vital_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Informe campos validos; data deve estar em ISO 8601"}), 400
    if status == 404:
        return jsonify({"erro": "Sinal vital nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o sinal vital"}), 500
    return jsonify(sinal.to_dict), 200


def deletar_sinal_vital(sinal_vital_id):
    _, status = sinal_vital_service.deletar(sinal_vital_id)
    if status == 404:
        return jsonify({"erro": "Sinal vital nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o sinal vital"}), 500
    return "", 204
