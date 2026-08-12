from flask import Blueprint

from controllers.paciente.registro_controller import (
    atualizar_registro, buscar_registro, criar_registro, deletar_registro,
    listar_registros, buscar_foto_lesao,
)


registros_pacientebp = Blueprint("registros_paciente", __name__)

# Cada recurso segue a mesma convencao: colecao dentro do paciente e item por ID.
for recurso in ("diarios-saude", "checklists-higiene", "estoque", "lesoes", "registros-financeiros"):
    prefixo = f"/pacientes/<int:paciente_id>/{recurso}"
    registros_pacientebp.add_url_rule(
        prefixo, endpoint=f"criar_{recurso}", methods=["POST"],
        view_func=lambda paciente_id, r=recurso: criar_registro(r, paciente_id),
    )
    registros_pacientebp.add_url_rule(
        prefixo, endpoint=f"listar_{recurso}", methods=["GET"],
        view_func=lambda paciente_id, r=recurso: listar_registros(r, paciente_id),
    )
    item = f"/{recurso}/<int:registro_id>"
    registros_pacientebp.add_url_rule(
        item, endpoint=f"buscar_{recurso}", methods=["GET"],
        view_func=lambda registro_id, r=recurso: buscar_registro(r, registro_id),
    )
    registros_pacientebp.add_url_rule(
        item, endpoint=f"atualizar_{recurso}", methods=["PUT", "PATCH"],
        view_func=lambda registro_id, r=recurso: atualizar_registro(r, registro_id),
    )
    registros_pacientebp.add_url_rule(
        item, endpoint=f"deletar_{recurso}", methods=["DELETE"],
        view_func=lambda registro_id, r=recurso: deletar_registro(r, registro_id),
    )

registros_pacientebp.route("/lesoes/<int:registro_id>/foto", methods=["GET"])(buscar_foto_lesao)
