from io import BytesIO

from flask import jsonify, request, send_file

from services.paciente.relatorio_service import RelatorioService


service = RelatorioService()


def gerar_relatorio(paciente_id):
    try:
        mes = int(request.args["mes"]) if "mes" in request.args else None
        ano = int(request.args["ano"]) if "ano" in request.args else None
    except ValueError:
        return jsonify({"erro": "Mes e ano devem ser numeros validos"}), 400
    valor_todo = request.args.get("todo_historico", "false").lower()
    if valor_todo not in {"true", "false"}:
        return jsonify({"erro": "todo_historico deve ser true ou false"}), 400
    todo_historico = valor_todo == "true"
    pdf, status = service.gerar(
        paciente_id, ano, mes, request.args.get("inicio"), request.args.get("fim"),
        todo_historico,
    )
    if status != 200:
        mensagem = "Periodo invalido" if status == 400 else "Paciente nao encontrado"
        return jsonify({"erro": mensagem}), status
    return send_file(BytesIO(pdf), mimetype="application/pdf", as_attachment=True, download_name=f"relatorio-paciente-{paciente_id}.pdf")


def enviar_historico(paciente_id):
    dados = request.get_json(silent=True) or {}
    enviado, status = service.enviar_email(
        paciente_id, dados.get("email"), dados.get("ano"), dados.get("mes"),
        dados.get("inicio"), dados.get("fim"), dados.get("todo_historico", False),
    )
    mensagens = {202: "Historico enviado", 400: "E-mail ou periodo invalido", 404: "Paciente nao encontrado", 502: "Falha ao enviar e-mail", 503: "Servidor SMTP nao configurado"}
    return jsonify({"mensagem" if enviado else "erro": mensagens[status]}), status


def evolucao_sinais_vitais(paciente_id):
    evolucao, status = service.evolucao_sinais_vitais(paciente_id)
    if status != 200:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify(evolucao), 200


def alertas_estoque(paciente_id):
    alertas, status = service.alertas_estoque(paciente_id)
    if status != 200:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify(alertas), 200
