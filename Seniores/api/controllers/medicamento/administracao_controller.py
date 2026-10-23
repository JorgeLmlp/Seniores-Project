from flask import jsonify, request

from services.administracao_medicamento_service import AdministracaoMedicamentoService


service = AdministracaoMedicamentoService()


def listar_administracoes(medicamento_id):
    administracoes, status = service.listar(medicamento_id)
    if status == 404:
        return jsonify({"erro": "Medicamento não encontrado"}), 404
    return jsonify([administracao.to_dict for administracao in administracoes]), 200


def criar_administracao(medicamento_id):
    administracao, status = service.criar(
        medicamento_id, request.get_json(silent=True) or {}
    )
    if status == 404:
        return jsonify({"erro": "Medicamento não encontrado"}), 404
    if status == 400:
        return jsonify({"erro": "Horário, responsável e data informados devem ser válidos"}), 400
    if status == 500:
        return jsonify({"erro": "Não foi possível registrar a dose"}), 500
    return jsonify(administracao.to_dict), 201


def atualizar_administracao(administracao_id):
    administracao, status = service.atualizar(
        administracao_id, request.get_json(silent=True) or {}
    )
    if status == 404:
        return jsonify({"erro": "Administração não encontrada"}), 404
    if status == 400:
        return jsonify({"erro": "Horário não pode ser vazio"}), 400
    if status == 500:
        return jsonify({"erro": "Não foi possível atualizar a dose"}), 500
    return jsonify(administracao.to_dict), 200


def deletar_administracao(administracao_id):
    _, status = service.deletar(administracao_id)
    if status == 404:
        return jsonify({"erro": "Administração não encontrada"}), 404
    if status == 500:
        return jsonify({"erro": "Não foi possível excluir a dose"}), 500
    return "", 204
