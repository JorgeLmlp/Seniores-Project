from flask import Blueprint
from controllers.medicamento.medicamento_controller import (
    atualizar_medicamento,
    buscar_medicamento,
    criar_medicamento,
    deletar_medicamento,
    listar_medicamentos,
)

medicamentobp = Blueprint("medicamentos", __name__)

# As duas primeiras rotas usam o paciente para criar ou obter sua lista.
medicamentobp.route("/pacientes/<int:paciente_id>/medicamentos", methods=["POST"])(criar_medicamento)
medicamentobp.route("/pacientes/<int:paciente_id>/medicamentos", methods=["GET"])(listar_medicamentos)
# Depois do cadastro, o ID do medicamento basta para consultar, editar ou remover.
medicamentobp.route("/medicamentos/<int:medicamento_id>", methods=["GET"])(buscar_medicamento)
medicamentobp.route("/medicamentos/<int:medicamento_id>", methods=["PUT", "PATCH"])(atualizar_medicamento)
medicamentobp.route("/medicamentos/<int:medicamento_id>", methods=["DELETE"])(deletar_medicamento)
