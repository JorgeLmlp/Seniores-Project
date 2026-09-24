from io import BytesIO

from flask import jsonify, request, send_file

from services.paciente.paciente_registro_service import PacienteRegistroService


registro_service = PacienteRegistroService()


def criar_registro(recurso, paciente_id):
    registro, status = registro_service.criar(recurso, paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Dados obrigatorios ausentes ou invalidos"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o registro"}), 500
    return jsonify(registro.to_dict), 201


def listar_registros(recurso, paciente_id):
    registros, status = registro_service.listar(recurso, paciente_id)
    if status == 400:
        return jsonify({"erro": "Recurso invalido"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([registro.to_dict for registro in registros]), 200


def buscar_registro(recurso, registro_id):
    registro, status = registro_service.buscar(recurso, registro_id)
    if status == 400:
        return jsonify({"erro": "Recurso invalido"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    return jsonify(registro.to_dict), 200


def atualizar_registro(recurso, registro_id):
    registro, status = registro_service.atualizar(recurso, registro_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Dados invalidos ou nenhum campo editavel informado"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o registro"}), 500
    return jsonify(registro.to_dict), 200


def deletar_registro(recurso, registro_id):
    _, status = registro_service.deletar(recurso, registro_id)
    if status == 400:
        return jsonify({"erro": "Recurso invalido"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o registro"}), 500
    return "", 204


def buscar_foto_lesao(registro_id):
    lesao, status = registro_service.buscar("lesoes", registro_id)
    if status == 404:
        return jsonify({"erro": "Lesao nao encontrada"}), 404
    if not lesao.foto:
        return jsonify({"erro": "A lesao nao possui foto"}), 404
    return send_file(BytesIO(lesao.foto), mimetype=lesao.foto_mime, download_name=f"lesao-{lesao.id}")
