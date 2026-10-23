from flask import jsonify, request

from services.emergencia_service import EmergenciaService


service = EmergenciaService()


def listar_contatos(paciente_id):
    contatos, status = service.listar_contatos(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([contato.to_dict for contato in contatos]), 200


def criar_contato(paciente_id):
    contato, status = service.criar_contato(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Nome e telefone sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o contato"}), 500
    return jsonify(contato.to_dict), 201


def buscar_contato(contato_id):
    contato, status = service.buscar_contato(contato_id)
    if status == 404:
        return jsonify({"erro": "Contato nao encontrado"}), 404
    return jsonify(contato.to_dict), 200


def atualizar_contato(contato_id):
    contato, status = service.atualizar_contato(
        contato_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Nome e telefone nao podem ser vazios"}), 400
    if status == 404:
        return jsonify({"erro": "Contato nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o contato"}), 500
    return jsonify(contato.to_dict), 200


def deletar_contato(contato_id):
    _, status = service.deletar_contato(contato_id)
    if status == 404:
        return jsonify({"erro": "Contato nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o contato"}), 500
    return "", 204


def listar_alertas(paciente_id):
    alertas, status = service.listar_alertas(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([alerta.to_dict for alerta in alertas]), 200


def criar_alerta(paciente_id):
    alerta, status = service.criar_alerta(paciente_id, request.get_json(silent=True) or {})
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel emitir o alerta"}), 500
    return jsonify(alerta.to_dict), 201


def resolver_alerta(alerta_id):
    alerta, status = service.resolver_alerta(alerta_id)
    if status == 404:
        return jsonify({"erro": "Alerta nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel resolver o alerta"}), 500
    return jsonify(alerta.to_dict), 200
