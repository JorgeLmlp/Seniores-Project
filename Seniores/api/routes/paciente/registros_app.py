from flask import Blueprint, jsonify
from services.paciente.envio_comunicado_service import enviar_comunicado_email

from controllers.paciente.registro_app_controller import (
    atualizar_registro_app,
    buscar_registro_app,
    criar_registro_app,
    deletar_registro_app,
    listar_registros_app,
)


registros_appbp = Blueprint("registros_app", __name__)

for recurso in ("consultas", "exames", "cuidadores", "destinatarios", "comunicados", "gastos"):
    colecao = f"/pacientes/<int:paciente_id>/{recurso}"
    registros_appbp.add_url_rule(
        colecao,
        endpoint=f"criar_app_{recurso}",
        methods=["POST"],
        view_func=lambda paciente_id, r=recurso: criar_registro_app(r, paciente_id),
    )
    registros_appbp.add_url_rule(
        colecao,
        endpoint=f"listar_app_{recurso}",
        methods=["GET"],
        view_func=lambda paciente_id, r=recurso: listar_registros_app(r, paciente_id),
    )
    item = f"/{recurso}/<int:registro_id>"
    registros_appbp.add_url_rule(
        item,
        endpoint=f"buscar_app_{recurso}",
        methods=["GET"],
        view_func=lambda registro_id, r=recurso: buscar_registro_app(r, registro_id),
    )
    registros_appbp.add_url_rule(
        item,
        endpoint=f"atualizar_app_{recurso}",
        methods=["PUT", "PATCH"],
        view_func=lambda registro_id, r=recurso: atualizar_registro_app(r, registro_id),
    )
    registros_appbp.add_url_rule(
        item,
        endpoint=f"deletar_app_{recurso}",
        methods=["DELETE"],
        view_func=lambda registro_id, r=recurso: deletar_registro_app(r, registro_id),
    )


@registros_appbp.post('/comunicados/<int:registro_id>/enviar')
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
