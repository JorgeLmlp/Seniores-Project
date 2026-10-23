from flask import jsonify, request, send_file

from services.documento_exame_service import DocumentoExameService, current_upload_folder


service = DocumentoExameService()


def listar_documentos_exame(exame_id):
    documentos, status = service.listar(exame_id)
    if status == 404:
        return jsonify({"erro": "Exame não encontrado"}), 404
    return jsonify([documento.to_dict for documento in documentos]), 200


def enviar_documento_exame(exame_id):
    documento, erro = service.salvar(exame_id, request.files.get("arquivo"))
    if erro == "exame_nao_encontrado":
        return jsonify({"erro": "Exame não encontrado"}), 404
    if erro == "arquivo_obrigatorio":
        return jsonify({"erro": "Arquivo é obrigatório"}), 400
    if erro == "formato_invalido":
        return jsonify({"erro": "Formato permitido: PDF, JPEG, PNG ou WebP"}), 400
    if erro == "arquivo_grande":
        return jsonify({"erro": "O arquivo deve ter no máximo 10 MB"}), 400
    if erro:
        return jsonify({"erro": "Não foi possível salvar o documento"}), 500
    return jsonify(documento.to_dict), 201


def baixar_documento_exame(documento_id):
    documento = service.buscar(documento_id)
    if not documento:
        return jsonify({"erro": "Documento não encontrado"}), 404
    caminho = (
        current_upload_folder()
        + "/exames/"
        + documento.nome_armazenado
    )
    return send_file(
        caminho,
        mimetype=documento.mime_type,
        as_attachment=False,
        download_name=documento.nome,
    )


def deletar_documento_exame(documento_id):
    _, status = service.deletar(documento_id)
    if status == 404:
        return jsonify({"erro": "Documento não encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível excluir o documento"}), 500
    return "", 204
