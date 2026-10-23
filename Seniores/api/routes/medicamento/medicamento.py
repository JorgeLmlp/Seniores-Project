from flask import Blueprint
from controllers.medicamento.medicamento_controller import (
    atualizar_medicamento,
    buscar_medicamento,
    criar_medicamento,
    deletar_medicamento,
    listar_medicamentos,
)
from controllers.medicamento.foto_controller import (
    baixar_foto_medicamento,
    deletar_foto_medicamento,
    enviar_foto_medicamento,
)
from controllers.medicamento.administracao_controller import (
    atualizar_administracao,
    criar_administracao,
    deletar_administracao,
    listar_administracoes,
)

medicamentobp = Blueprint("medicamentos", __name__)

# As duas primeiras rotas usam o paciente para criar ou obter sua lista.
medicamentobp.route("/pacientes/<int:paciente_id>/medicamentos", methods=["POST"])(criar_medicamento)
medicamentobp.route("/pacientes/<int:paciente_id>/medicamentos", methods=["GET"])(listar_medicamentos)
# Depois do cadastro, o ID do medicamento basta para consultar, editar ou remover.
medicamentobp.route("/medicamentos/<int:medicamento_id>", methods=["GET"])(buscar_medicamento)
medicamentobp.route("/medicamentos/<int:medicamento_id>", methods=["PUT", "PATCH"])(atualizar_medicamento)
medicamentobp.route("/medicamentos/<int:medicamento_id>", methods=["DELETE"])(deletar_medicamento)
medicamentobp.route(
    "/medicamentos/<int:medicamento_id>/foto", methods=["POST"]
)(enviar_foto_medicamento)
medicamentobp.route(
    "/medicamentos/<int:medicamento_id>/foto", methods=["GET"]
)(baixar_foto_medicamento)
medicamentobp.route(
    "/medicamentos/<int:medicamento_id>/foto", methods=["DELETE"]
)(deletar_foto_medicamento)
medicamentobp.route(
    "/medicamentos/<int:medicamento_id>/administracoes", methods=["GET"]
)(listar_administracoes)
medicamentobp.route(
    "/medicamentos/<int:medicamento_id>/administracoes", methods=["POST"]
)(criar_administracao)
medicamentobp.route(
    "/administracoes-medicamentos/<int:administracao_id>",
    methods=["PATCH", "PUT"],
)(atualizar_administracao)
medicamentobp.route(
    "/administracoes-medicamentos/<int:administracao_id>",
    methods=["DELETE"],
)(deletar_administracao)

