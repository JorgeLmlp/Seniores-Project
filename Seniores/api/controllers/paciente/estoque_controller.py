from flask import jsonify, request

from services.estoque_service import EstoqueService


service = EstoqueService()


def listar_estoque(paciente_id):
    itens, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([item.to_dict for item in itens]), 200


def criar_item(paciente_id):
    item, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Nome e quantidades validas sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o item"}), 500
    return jsonify(item.to_dict), 201


def buscar_item(item_id):
    item, status = service.buscar(item_id)
    if status == 404:
        return jsonify({"erro": "Item nao encontrado"}), 404
    return jsonify(item.to_dict), 200


def atualizar_item(item_id):
    item, status = service.atualizar(item_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Dados invalidos para o item"}), 400
    if status == 404:
        return jsonify({"erro": "Item nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o item"}), 500
    return jsonify(item.to_dict), 200


def deletar_item(item_id):
    _, status = service.deletar(item_id)
    if status == 404:
        return jsonify({"erro": "Item nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o item"}), 500
    return "", 204
