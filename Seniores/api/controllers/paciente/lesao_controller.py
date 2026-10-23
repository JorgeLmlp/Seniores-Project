from flask import jsonify, request, send_file

from services.foto_lesao_service import FotoLesaoService
from services.lesao_service import LesaoService


service = LesaoService()
foto_service = FotoLesaoService()


def listar_lesoes(paciente_id):
    lesoes, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([lesao.to_dict for lesao in lesoes]), 200


def criar_lesao(paciente_id):
    lesao, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Localizacao, data de inicio e descricao sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar a lesao"}), 500
    return jsonify(lesao.to_dict), 201


def buscar_lesao(lesao_id):
    lesao, status = service.buscar(lesao_id)
    if status == 404:
        return jsonify({"erro": "Lesao nao encontrada"}), 404
    return jsonify(lesao.to_dict), 200


def atualizar_lesao(lesao_id):
    lesao, status = service.atualizar(
        lesao_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Campos obrigatorios nao podem ser vazios"}), 400
    if status == 404:
        return jsonify({"erro": "Lesao nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar a lesao"}), 500
    return jsonify(lesao.to_dict), 200


def deletar_lesao(lesao_id):
    _, status = service.deletar(lesao_id)
    if status == 404:
        return jsonify({"erro": "Lesao nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover a lesao"}), 500
    return "", 204


def enviar_foto_lesao(lesao_id):
    lesao, erro = foto_service.salvar(lesao_id, request.files.get("foto"))
    mensagens = {
        "lesao_nao_encontrada": ("Lesao nao encontrada", 404),
        "arquivo_obrigatorio": ("Foto e obrigatoria", 400),
        "formato_invalido": ("Formato permitido: JPEG, PNG ou WebP", 400),
        "arquivo_grande": ("A foto deve ter no maximo 5 MB", 400),
    }
    if erro in mensagens:
        mensagem, status = mensagens[erro]
        return jsonify({"erro": mensagem}), status
    if erro:
        return jsonify({"erro": "Nao foi possivel salvar a foto"}), 500
    return jsonify(lesao.to_dict), 201


def baixar_foto_lesao(lesao_id):
    resultado = foto_service.caminho(lesao_id)
    if not resultado:
        return jsonify({"erro": "Foto nao encontrada"}), 404
    lesao, caminho = resultado
    if not caminho:
        return jsonify({"erro": "Foto nao encontrada"}), 404
    return send_file(
        caminho,
        mimetype=lesao.foto_mime,
        as_attachment=False,
        download_name=lesao.foto_nome,
    )


def deletar_foto_lesao(lesao_id):
    _, status = foto_service.remover(lesao_id)
    if status == 404:
        return jsonify({"erro": "Lesao nao encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel excluir a foto"}), 500
    return "", 204
