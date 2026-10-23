from flask import jsonify, request

from services.dieta_service import DietaService


service = DietaService()


def listar_dietas(paciente_id):
    dietas, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([dieta.to_dict for dieta in dietas]), 200


def criar_dieta(paciente_id):
    dieta, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Tipo, data de inicio e descricao sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar a dieta"}), 500
    return jsonify(dieta.to_dict), 201


def buscar_dieta(dieta_id):
    dieta, status = service.buscar(dieta_id)
    if status == 404:
        return jsonify({"erro": "Dieta nao encontrada"}), 404
    return jsonify(dieta.to_dict), 200


def atualizar_dieta(dieta_id):
    dieta, status = service.atualizar(
        dieta_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Campos obrigatorios nao podem ser vazios"}), 400
    if status == 404:
        return jsonify({"erro": "Dieta nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar a dieta"}), 500
    return jsonify(dieta.to_dict), 200


def deletar_dieta(dieta_id):
    _, status = service.deletar(dieta_id)
    if status == 404:
        return jsonify({"erro": "Dieta nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover a dieta"}), 500
    return "", 204
