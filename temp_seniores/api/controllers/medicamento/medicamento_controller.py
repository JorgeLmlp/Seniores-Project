from flask import jsonify, request
from services.medicamento_service import MedicamentoService


medicamento_service = MedicamentoService()


def criar_medicamento(paciente_id):
    """Cadastra um medicamento ja associado ao paciente da URL."""
    medicamento, status = medicamento_service.criar(
        paciente_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Nome e dosagem sao obrigatorios; quantidade deve ser um inteiro nao negativo"}), 400
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel salvar o medicamento"}), 500
    return jsonify(medicamento.to_dict), status


def listar_medicamentos(paciente_id):
    """Devolve a lista que sera exibida na tela do paciente."""
    medicamentos, status = medicamento_service.listar(paciente_id)
    if status == 404:
        return jsonify({"erro": "Paciente nao encontrado"}), 404
    return jsonify([medicamento.to_dict for medicamento in medicamentos]), 200


def buscar_medicamento(medicamento_id):
    """Consulta um item da lista pelo ID do medicamento."""
    medicamento, status = medicamento_service.buscar(medicamento_id)
    if status == 404:
        return jsonify({"erro": "Medicamento nao encontrado"}), 404
    return jsonify(medicamento.to_dict), 200


def atualizar_medicamento(medicamento_id):
    """Altera campos enviados sem exigir que todo o objeto seja reenviado."""
    medicamento, status = medicamento_service.atualizar(
        medicamento_id, request.get_json(silent=True) or {}
    )
    if status == 400:
        return jsonify({"erro": "Nome e dosagem sao obrigatorios; quantidade deve ser um inteiro nao negativo"}), 400
    if status == 404:
        return jsonify({"erro": "Medicamento nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel atualizar o medicamento"}), 500
    return jsonify(medicamento.to_dict), 200


def deletar_medicamento(medicamento_id):
    """Remove definitivamente um medicamento da lista."""
    _, status = medicamento_service.deletar(medicamento_id)
    if status == 404:
        return jsonify({"erro": "Medicamento nao encontrado"}), 404
    if status == 500:
        return jsonify({"erro": "Nao foi possivel remover o medicamento"}), 500
    return "", 204
