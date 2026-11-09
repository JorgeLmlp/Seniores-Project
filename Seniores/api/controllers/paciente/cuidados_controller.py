from flask import jsonify, request

from services.paciente.cuidados_service import CuidadosService


service = CuidadosService()


def criar(recurso, paciente_id):
    registro, status = service.criar(recurso, paciente_id, request.get_json(silent=True) or {})
    if status != 201:
        mensagens = {400: "Dados invalidos", 404: "Paciente nao encontrado", 500: "Nao foi possivel salvar"}
        return jsonify({"erro": mensagens[status]}), status
    return jsonify(registro.to_dict), 201


def listar(recurso, paciente_id):
    registros, status = service.listar(recurso, paciente_id)
    if status != 200:
        return jsonify({"erro": "Paciente ou recurso nao encontrado"}), status
    return jsonify([registro.to_dict for registro in registros]), 200


def buscar(recurso, registro_id):
    registro, status = service.buscar(recurso, registro_id)
    if status != 200:
        return jsonify({"erro": "Registro nao encontrado"}), status
    return jsonify(registro.to_dict), 200


def atualizar(recurso, registro_id):
    registro, status = service.atualizar(recurso, registro_id, request.get_json(silent=True) or {})
    if status != 200:
        return jsonify({"erro": "Registro nao encontrado ou dados invalidos"}), status
    return jsonify(registro.to_dict), 200


def deletar(recurso, registro_id):
    _, status = service.deletar(recurso, registro_id)
    if status != 204:
        return jsonify({"erro": "Registro nao encontrado"}), status
    return "", 204
