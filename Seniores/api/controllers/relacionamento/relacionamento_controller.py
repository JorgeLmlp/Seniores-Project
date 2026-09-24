from flask import jsonify, request
from services.relacionamento.relacionamento_service import RelacionamentoService


relacionamento_service = RelacionamentoService()


def vincular_responsavel():
    """Recebe os dois CPFs e devolve os IDs que formam o vinculo."""
    vinculo, status = relacionamento_service.vincular_responsavel(
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
    paciente, status = relacionamento_service.vincular_paciente_cuidador(
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
    vinculo, status = relacionamento_service.vincular_cuidador_responsavel(
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
