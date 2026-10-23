from flask import jsonify, request

from services.higiene_service import HigieneService


service = HigieneService()


def listar_higienes(paciente_id):
    higienes, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([higiene.to_dict for higiene in higienes]), 200


def criar_higiene(paciente_id):
    higiene, status = service.criar(
        paciente_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({
            "erro": "Tipo, data/hora e ao menos um item do checklist sao obrigatorios"
        }), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar a rotina de higiene"}), 500
    return jsonify(higiene.to_dict), 201


def buscar_higiene(higiene_id):
    higiene, status = service.buscar(higiene_id)
    if status == 404:
        return jsonify({"erro": "Rotina de higiene nao encontrada"}), 404
    return jsonify(higiene.to_dict), 200


def atualizar_higiene(higiene_id):
    higiene, status = service.atualizar(
        higiene_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Tipo, data/hora e checklist sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Rotina de higiene nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar a rotina de higiene"}), 500
    return jsonify(higiene.to_dict), 200


def deletar_higiene(higiene_id):
    _, status = service.deletar(higiene_id)
    if status == 404:
        return jsonify({"erro": "Rotina de higiene nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover a rotina de higiene"}), 500
    return "", 204
