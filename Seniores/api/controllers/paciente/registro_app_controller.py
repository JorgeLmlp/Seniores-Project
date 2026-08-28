from flask import jsonify, request

from services.agenda_cuidador_service import AgendaCuidadorService
from services.comunicado_service import ComunicadoService
from services.consulta_service import ConsultaService
from services.destinatario_service import DestinatarioService
from services.exame_service import ExameService


SERVICOS = {
    "consultas": ConsultaService(),
    "exames": ExameService(),
    "cuidadores": AgendaCuidadorService(),
    "destinatarios": DestinatarioService(),
    "comunicados": ComunicadoService(),
}


def _service(recurso):
    return SERVICOS.get(recurso)


def criar_registro_app(recurso, paciente_id):
    service = _service(recurso)
    if service is None:
        return jsonify({"erro": "Recurso invalido"}), 400
    registro, status = service.criar(paciente_id, request.get_json(silent=True) or {})
    if status == 400:
        return jsonify({"erro": "Recurso ou dados invalidos"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o registro"}), 500
    return jsonify(registro.to_dict), 201


def listar_registros_app(recurso, paciente_id):
    service = _service(recurso)
    if service is None:
        return jsonify({"erro": "Recurso invalido"}), 400
    registros, status = service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([registro.to_dict for registro in registros]), 200


def buscar_registro_app(recurso, registro_id):
    service = _service(recurso)
    if service is None:
        return jsonify({"erro": "Recurso invalido"}), 400
    registro, status = service.buscar(registro_id)
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    return jsonify(registro.to_dict), 200


def atualizar_registro_app(recurso, registro_id):
    service = _service(recurso)
    if service is None:
        return jsonify({"erro": "Recurso invalido"}), 400
    registro, status = service.atualizar(
        registro_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Dados invalidos"}), 400
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o registro"}), 500
    return jsonify(registro.to_dict), 200


def deletar_registro_app(recurso, registro_id):
    service = _service(recurso)
    if service is None:
        return jsonify({"erro": "Recurso invalido"}), 400
    _, status = service.deletar(registro_id)
    if status == 404:
        return jsonify({"erro": "Registro nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o registro"}), 500
    return "", 204
