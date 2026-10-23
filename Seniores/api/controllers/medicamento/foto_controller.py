from flask import jsonify, request, send_file

from services.foto_medicamento_service import FotoMedicamentoService


service = FotoMedicamentoService()


def enviar_foto_medicamento(medicamento_id):
    medicamento, erro = service.salvar(
        medicamento_id, request.files.get("foto")
    )
    if erro == "medicamento_nao_encontrado":
        return jsonify({"erro": "Medicamento não encontrado"}), 404
    if erro == "arquivo_obrigatorio":
        return jsonify({"erro": "Foto é obrigatória"}), 400
    if erro == "formato_invalido":
        return jsonify({"erro": "Formato permitido: JPEG, PNG ou WebP"}), 400
    if erro == "arquivo_grande":
        return jsonify({"erro": "A foto deve ter no máximo 5 MB"}), 400
    if erro:
        return jsonify({"erro": "Não foi possível salvar a foto"}), 500
    return jsonify(medicamento.to_dict), 201


def baixar_foto_medicamento(medicamento_id):
    resultado = service.caminho(medicamento_id)
    if not resultado:
        return jsonify({"erro": "Foto não encontrada"}), 404
    medicamento, caminho = resultado
    if not caminho:
        return jsonify({"erro": "Foto não encontrada"}), 404
    return send_file(
        caminho,
        mimetype=medicamento.foto_mime,
        as_attachment=False,
        download_name=medicamento.foto_nome,
    )


def deletar_foto_medicamento(medicamento_id):
    _, status = service.remover(medicamento_id)
    if status == 404:
        return jsonify({"erro": "Medicamento não encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível excluir a foto"}), 500
    return "", 204
