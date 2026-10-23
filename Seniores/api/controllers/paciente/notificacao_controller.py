from flask import jsonify

from services.notificacao_service import NotificacaoService


service = NotificacaoService()


def listar_notificacoes(paciente_id):
    notificacoes, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([notificacao.to_dict for notificacao in notificacoes]), 200


def marcar_lida(notificacao_id):
    notificacao, status = service.marcar(notificacao_id, True)
    if status == 404:
        return jsonify({"erro": "Notificacao nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel marcar a notificacao"}), 500
    return jsonify(notificacao.to_dict), 200


def marcar_nao_lida(notificacao_id):
    notificacao, status = service.marcar(notificacao_id, False)
    if status == 404:
        return jsonify({"erro": "Notificacao nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar a notificacao"}), 500
    return jsonify(notificacao.to_dict), 200
