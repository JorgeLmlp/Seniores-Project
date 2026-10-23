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


def listar_sinais_vitais():
    return jsonify([sinal.to_dict for sinal in sinal_vital_service.listar()]), 200


def atualizar_sinal_vital(sinal_id):
    sinal, status = sinal_vital_service.atualizar(
        sinal_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Informe ao menos um campo válido"}), 400
    if status == 404:
        return jsonify({"erro": "Sinal vital não encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível atualizar o sinal vital"}), 500
    return jsonify(sinal.to_dict), 200


def deletar_sinal_vital(sinal_id):
    _, status = sinal_vital_service.deletar(sinal_id)
    if status == 404:
        return jsonify({"erro": "Sinal vital não encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível excluir o sinal vital"}), 500
    return "", 204
