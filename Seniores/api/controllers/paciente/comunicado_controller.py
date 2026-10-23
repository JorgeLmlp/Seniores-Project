from flask import jsonify, request

from services.comunicado_service import ComunicadoService


service = ComunicadoService()


def listar_comunicados(paciente_id):
    comunicados, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente não encontrado"}), 404
    return jsonify([comunicado.to_dict for comunicado in comunicados]), 200


def criar_comunicado(paciente_id):
    comunicado, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 404:
        return jsonify({"erro": "Paciente não encontrado"}), 404
    if status == 400:
        return jsonify({
            "erro": "Título, mensagem e ao menos um destinatário vinculado são obrigatórios"
        }), 400
    if status == 500:
        return jsonify({"erro": "Não foi possível enviar o comunicado"}), 500
    return jsonify(comunicado.to_dict), 201


def atualizar_comunicado(paciente_id, comunicado_id):
    comunicado, status = service.atualizar(
        paciente_id, comunicado_id, request.get_json(silent=True) or {}
    )
    if status == 404:
        return jsonify({"erro": "Comunicado não encontrado"}), 404
    if status == 400:
        return jsonify({
            "erro": "Título, mensagem e ao menos um destinatário vinculado são obrigatórios"
        }), 400
    if status == 500:
        return jsonify({"erro": "Não foi possível atualizar o comunicado"}), 500
    return jsonify(comunicado.to_dict), 200


def deletar_comunicado(paciente_id, comunicado_id):
    _, status = service.deletar(paciente_id, comunicado_id)
    if status == 404:
        return jsonify({"erro": "Comunicado não encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível excluir o comunicado"}), 500
    return "", 204


def reenviar_comunicado(paciente_id, comunicado_id):
    comunicado, status = service.reenviar(paciente_id, comunicado_id)
    if status == 404:
        return jsonify({"erro": "Comunicado não encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível reenviar o comunicado"}), 500
    return jsonify(comunicado.to_dict), 200
