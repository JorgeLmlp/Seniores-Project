from flask import jsonify, request

from services.gasto_service import GastoService


service = GastoService()


def listar_gastos(paciente_id):
    gastos, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([gasto.to_dict for gasto in gastos]), 200


def criar_gasto(paciente_id):
    gasto, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Descricao, valor e data validos sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o gasto"}), 500
    return jsonify(gasto.to_dict), 201


def buscar_gasto(gasto_id):
    gasto, status = service.buscar(gasto_id)
    if status == 404:
        return jsonify({"erro": "Gasto nao encontrado"}), 404
    return jsonify(gasto.to_dict), 200


def atualizar_gasto(gasto_id):
    gasto, status = service.atualizar(gasto_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Dados invalidos para o gasto"}), 400
    if status == 404:
        return jsonify({"erro": "Gasto nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o gasto"}), 500
    return jsonify(gasto.to_dict), 200


def deletar_gasto(gasto_id):
    _, status = service.deletar(gasto_id)
    if status == 404:
        return jsonify({"erro": "Gasto nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o gasto"}), 500
    return "", 204
