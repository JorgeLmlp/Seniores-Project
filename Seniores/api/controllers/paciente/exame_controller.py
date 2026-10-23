from flask import jsonify, request

from services.exame_service import ExameService


service = ExameService()


def listar_exames(paciente_id):
    exames, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([exame.to_dict for exame in exames]), 200


def criar_exame(paciente_id):
    exame, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Nome e data sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o exame"}), 500
    return jsonify(exame.to_dict), 201


def buscar_exame(exame_id):
    exame, status = service.buscar(exame_id)
    if status == 404:
        return jsonify({"erro": "Exame nao encontrado"}), 404
    return jsonify(exame.to_dict), 200


def atualizar_exame(exame_id):
    exame, status = service.atualizar(
        exame_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Nome e data nao podem ser vazios"}), 400
    if status == 404:
        return jsonify({"erro": "Exame nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o exame"}), 500
    return jsonify(exame.to_dict), 200


def deletar_exame(exame_id):
    _, status = service.deletar(exame_id)
    if status == 404:
        return jsonify({"erro": "Exame nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o exame"}), 500
    return "", 204
