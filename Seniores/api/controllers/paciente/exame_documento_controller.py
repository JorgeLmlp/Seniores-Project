from io import BytesIO

from flask import jsonify, request, send_file

from services.paciente.exame_documento_service import ExameDocumentoService


service = ExameDocumentoService()


def criar_exame_documento(paciente_id):
    registro, status = service.criar(paciente_id, request.form, request.files.get("arquivo"))
    if status != 201:
        mensagens = {400: "Envie nome e arquivo PDF ou imagem de ate 10 MB", 404: "Paciente nao encontrado", 500: "Nao foi possivel salvar o exame"}
        return jsonify({"erro": mensagens[status]}), status
    return jsonify(registro.to_dict), 201


def listar_exames_documentos(paciente_id):
    registros, status = service.listar(paciente_id)
    if status != 200:
        return jsonify({"erro": "Paciente nao encontrado"}), status
    return jsonify([registro.to_dict for registro in registros]), 200


def baixar_exame_documento(registro_id):
    registro, status = service.buscar(registro_id)
    if status != 200:
        return jsonify({"erro": "Exame nao encontrado"}), 404
    return send_file(BytesIO(registro.arquivo), mimetype=registro.mime_type, download_name=registro.nome_arquivo)


def deletar_exame_documento(registro_id):
    _, status = service.deletar(registro_id)
    return ("", 204) if status == 204 else (jsonify({"erro": "Exame nao encontrado"}), status)
