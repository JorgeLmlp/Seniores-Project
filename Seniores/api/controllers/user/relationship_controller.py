from flask import jsonify, request
from services.relationship_service import RelationshipService
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel
from extensions import db


relationship_service = RelationshipService()


def vincular_responsavel():
    """Recebe os dois CPFs e devolve os IDs que formam o vinculo."""
    vinculo, status = relationship_service.vincular_responsavel(
        request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "CPFs do paciente e responsavel sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente ou responsavel nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o relacionamento"}), 500

    return jsonify({
        "paciente_id": vinculo.paciente_id,
        "responsavel_id": vinculo.responsavel_id,
    }), status


def vincular_paciente_cuidador():
    paciente, status = relationship_service.vincular_paciente_cuidador(
        request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "CPFs do paciente e cuidador sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente ou cuidador nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o relacionamento"}), 500
    return jsonify({"paciente_id": paciente.id, "cuidador_id": paciente.cuidador_id}), 200


def vincular_cuidador_responsavel():
    vinculo, status = relationship_service.vincular_cuidador_responsavel(
        request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "CPFs do cuidador e responsavel sao obrigatorios"}), 400
    if status == 404:
        return jsonify({"erro": "Cuidador ou responsavel nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o relacionamento"}), 500
    return jsonify({
        "cuidador_id": vinculo.cuidador_id,
        "responsavel_id": vinculo.responsavel_id,
    }), status


def listar_cuidador_paciente(paciente_id):
    paciente = Paciente.buscar_por_id(paciente_id)
    if not paciente:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify(paciente.cuidador.to_dict if paciente.cuidador else None), 200


def desvincular_cuidador_paciente(paciente_id):
    paciente = Paciente.buscar_por_id(paciente_id)
    if not paciente:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    paciente.cuidador_id = None
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({"erro": "Nao foi possivel desvincular o cuidador"}), 500
    return "", 204


def listar_responsaveis_paciente(paciente_id):
    paciente = Paciente.buscar_por_id(paciente_id)
    if not paciente:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([responsavel.to_dict for responsavel in paciente.responsaveis]), 200


def desvincular_responsavel_paciente(paciente_id, responsavel_id):
    paciente = Paciente.buscar_por_id(paciente_id)
    responsavel = Responsavel.buscar_por_id(responsavel_id)
    if not paciente or not responsavel:
        return jsonify({"erro": "Paciente ou responsavel nao encontrado"}), 404
    if responsavel in paciente.responsaveis:
        paciente.responsaveis.remove(responsavel)
    if paciente.responsavel_id == responsavel.id:
        paciente.responsavel_id = None
    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({"erro": "Nao foi possivel desvincular o responsavel"}), 500
    return "", 204
