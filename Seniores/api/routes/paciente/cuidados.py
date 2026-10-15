from flask import Blueprint

from controllers.paciente.cuidados_controller import atualizar, buscar, criar, deletar, listar


cuidadosbp = Blueprint("cuidados", __name__)

RECURSOS = (
    "administracoes-medicamentos", "incidentes", "contatos-emergencia",
    "turnos-cuidadores", "dietas-restricoes", "permissoes", "alertas-panico",
)

for recurso in RECURSOS:
    colecao = f"/pacientes/<int:paciente_id>/{recurso}"
    item = f"/{recurso}/<int:registro_id>"
    cuidadosbp.add_url_rule(colecao, endpoint=f"criar_{recurso}", methods=["POST"], view_func=lambda paciente_id, r=recurso: criar(r, paciente_id))
    cuidadosbp.add_url_rule(colecao, endpoint=f"listar_{recurso}", methods=["GET"], view_func=lambda paciente_id, r=recurso: listar(r, paciente_id))
    cuidadosbp.add_url_rule(item, endpoint=f"buscar_{recurso}", methods=["GET"], view_func=lambda registro_id, r=recurso: buscar(r, registro_id))
    cuidadosbp.add_url_rule(item, endpoint=f"atualizar_{recurso}", methods=["PUT", "PATCH"], view_func=lambda registro_id, r=recurso: atualizar(r, registro_id))
    cuidadosbp.add_url_rule(item, endpoint=f"deletar_{recurso}", methods=["DELETE"], view_func=lambda registro_id, r=recurso: deletar(r, registro_id))
