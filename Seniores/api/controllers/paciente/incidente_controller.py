from flask import jsonify, request

from services.incidente_service import IncidenteService


service = IncidenteService()


def listar_incidentes(paciente_id):
    incidentes, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([incidente.to_dict for incidente in incidentes]), 200


def criar_incidente(paciente_id):
    incidente, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Tipo, data/hora e descricao sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o incidente"}), 500
    return jsonify(incidente.to_dict), 201


def buscar_incidente(incidente_id):
    incidente, status = service.buscar(incidente_id)
    if status == 404:
        return jsonify({"erro": "Incidente nao encontrado"}), 404
    return jsonify(incidente.to_dict), 200


def atualizar_incidente(incidente_id):
    incidente, status = service.atualizar(
        incidente_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Campos obrigatorios nao podem ser vazios"}), 400
    if status == 404:
        return jsonify({"erro": "Incidente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o incidente"}), 500
    return jsonify(incidente.to_dict), 200


def deletar_incidente(incidente_id):
    _, status = service.deletar(incidente_id)
    if status == 404:
        return jsonify({"erro": "Incidente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o incidente"}), 500
    return "", 204
