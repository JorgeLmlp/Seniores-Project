from flask import jsonify, request
from services.relationship_service import RelationshipService


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
