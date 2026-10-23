from flask import Blueprint

from controllers.paciente.lesao_controller import (
    atualizar_lesao,
    baixar_foto_lesao,
    buscar_lesao,
    criar_lesao,
    deletar_foto_lesao,
    deletar_lesao,
    enviar_foto_lesao,
    listar_lesoes,
)


lesoesbp = Blueprint("lesoes", __name__)
lesoesbp.route("/pacientes/<int:paciente_id>/lesoes", methods=["GET"])(listar_lesoes)
lesoesbp.route("/pacientes/<int:paciente_id>/lesoes", methods=["POST"])(criar_lesao)
lesoesbp.route("/lesoes/<int:lesao_id>", methods=["GET"])(buscar_lesao)
lesoesbp.route("/lesoes/<int:lesao_id>", methods=["PUT", "PATCH"])(atualizar_lesao)
lesoesbp.route("/lesoes/<int:lesao_id>", methods=["DELETE"])(deletar_lesao)
lesoesbp.route("/lesoes/<int:lesao_id>/foto", methods=["POST"])(enviar_foto_lesao)
lesoesbp.route("/lesoes/<int:lesao_id>/foto", methods=["GET"])(baixar_foto_lesao)
lesoesbp.route("/lesoes/<int:lesao_id>/foto", methods=["DELETE"])(deletar_foto_lesao)
