from flask import jsonify, request

from services.registro_diario_service import RegistroDiarioService


service = RegistroDiarioService()


def listar_registros(paciente_id):
    registros, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([registro.to_dict for registro in registros]), 200


def criar_registro(paciente_id):
    registro, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Data e notas validas sao obrigatorias"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o registro"}), 500
    return jsonify(registro.to_dict), 201


def buscar_registro(registro_id):
    registro, status = service.buscar(registro_id)
    if status == 404:
        return jsonify({"erro": "Registro diario nao encontrado"}), 404
    return jsonify(registro.to_dict), 200


def atualizar_registro(registro_id):
    registro, status = service.atualizar(
        registro_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Dados invalidos para o registro"}), 400
    if status == 404:
        return jsonify({"erro": "Registro diario nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o registro"}), 500
    return jsonify(registro.to_dict), 200


def deletar_registro(registro_id):
    _, status = service.deletar(registro_id)
    if status == 404:
        return jsonify({"erro": "Registro diario nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o registro"}), 500
    return "", 204
