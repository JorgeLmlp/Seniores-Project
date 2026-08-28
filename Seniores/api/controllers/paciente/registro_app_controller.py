from flask import jsonify, request

from services.registro_app_service import RegistroAppService


service = RegistroAppService()


def criar_registro_app(recurso, paciente_id):
    registro, status = service.criar(
        recurso, paciente_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Recurso ou dados invalidos"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o registro"}), 500
    return jsonify(registro.to_dict), 201


def listar_registros_app(recurso, paciente_id):
    registros, status = service.listar(recurso, paciente_id)
    if status == 400:
        return jsonify({"erro": "Recurso invalido"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([registro.to_dict for registro in registros]), 200


def buscar_registro_app(recurso, registro_id):
    registro, status = service.buscar(recurso, registro_id)
    if status == 400:
        return jsonify({"erro": "Recurso invalido"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    return jsonify(registro.to_dict), 200


def atualizar_registro_app(recurso, registro_id):
    registro, status = service.atualizar(
        recurso, registro_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Dados invalidos"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o registro"}), 500
    return jsonify(registro.to_dict), 200


def deletar_registro_app(recurso, registro_id):
    _, status = service.deletar(recurso, registro_id)
    if status == 400:
        return jsonify({"erro": "Recurso invalido"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o registro"}), 500
    return "", 204

