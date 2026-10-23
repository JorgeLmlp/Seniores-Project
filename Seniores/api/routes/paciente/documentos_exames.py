from flask import Blueprint

from controllers.paciente.documento_exame_controller import (
    baixar_documento_exame,
    deletar_documento_exame,
    enviar_documento_exame,
    listar_documentos_exame,
)


documentos_examesbp = Blueprint("documentos_exames", __name__)
documentos_examesbp.route(
    "/exames/<int:exame_id>/documentos", methods=["GET"]
)(listar_documentos_exame)
documentos_examesbp.route(
    "/exames/<int:exame_id>/documentos", methods=["POST"]
)(enviar_documento_exame)
documentos_examesbp.route(
    "/documentos-exame/<int:documento_id>/arquivo", methods=["GET"]
)(baixar_documento_exame)
documentos_examesbp.route(
    "/documentos-exame/<int:documento_id>", methods=["DELETE"]
)(deletar_documento_exame)
