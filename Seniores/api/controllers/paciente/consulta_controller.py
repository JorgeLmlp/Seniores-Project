from flask import jsonify, request

from services.consulta_service import ConsultaService


service = ConsultaService()


def listar_consultas(paciente_id):
    consultas, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([consulta.to_dict for consulta in consultas]), 200


def criar_consulta(paciente_id):
    consulta, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Titulo e data sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar a consulta"}), 500
    return jsonify(consulta.to_dict), 201


def buscar_consulta(consulta_id):
    consulta, status = service.buscar(consulta_id)
    if status == 404:
        return jsonify({"erro": "Consulta nao encontrada"}), 404
    return jsonify(consulta.to_dict), 200


def atualizar_consulta(consulta_id):
    consulta, status = service.atualizar(
        consulta_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Titulo e data nao podem ser vazios"}), 400
    if status == 404:
        return jsonify({"erro": "Consulta nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar a consulta"}), 500
    return jsonify(consulta.to_dict), 200


def deletar_consulta(consulta_id):
    _, status = service.deletar(consulta_id)
    if status == 404:
        return jsonify({"erro": "Consulta nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover a consulta"}), 500
    return "", 204
