from flask import Blueprint

from controllers.paciente.registro_app_controller import (
    atualizar_registro_app,
    buscar_registro_app,
    criar_registro_app,
    deletar_registro_app,
    listar_registros_app,
)


registros_appbp = Blueprint("registros_app", __name__)

for recurso in ("consultas", "exames", "cuidadores", "destinatarios", "comunicados"):
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
