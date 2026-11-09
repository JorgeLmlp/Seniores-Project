from flask import jsonify
from services.paciente.envio_comunicado_service import enviar_comunicado_email

def enviar_comunicado(registro_id):
    registro, status = enviar_comunicado_email(registro_id)
    if status == 404:
        return jsonify(erro='Comunicado nao encontrado.'), 404
    if status == 400:
        return jsonify(erro='Todos os destinatarios precisam ter e-mail valido.'), 400
    if status == 429:
        return jsonify(erro='Limite de tentativas de envio atingido.'), 429
    if status == 503:
        return jsonify(erro='SMTP nao configurado. Comunicado permanece pendente.'), 503
    if status == 409:
        return jsonify(erro='Envio ja em andamento.'), 409
    if status == 502:
        return jsonify(erro='Falha ao enviar e-mail; status salvo como falhou.'), 502
    if status != 200:
        return jsonify(erro='Nao foi possivel atualizar o envio.'), 500
    return jsonify(registro.to_dict), 200
