from flask import Blueprint

from controllers.paciente.exame_documento_controller import (
    baixar_exame_documento, criar_exame_documento, deletar_exame_documento,
    listar_exames_documentos,
)


exames_documentosbp = Blueprint("exames_documentos", __name__)
exames_documentosbp.route("/pacientes/<int:paciente_id>/exames-documentos", methods=["POST"])(criar_exame_documento)
exames_documentosbp.route("/pacientes/<int:paciente_id>/exames-documentos", methods=["GET"])(listar_exames_documentos)
exames_documentosbp.route("/exames-documentos/<int:registro_id>/arquivo", methods=["GET"])(baixar_exame_documento)
exames_documentosbp.route("/exames-documentos/<int:registro_id>", methods=["DELETE"])(deletar_exame_documento)
