from flask import jsonify, request

from services.relatorio_service import RelatorioService


service = RelatorioService()


def enviar_historico_email():
    dados = request.get_json(silent=True) or {}
    resposta, status = service.enviar_por_email(
        dados.get("paciente_id"), dados.get("email")
    )
    return jsonify(resposta), status
