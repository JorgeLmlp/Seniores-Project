from flask import jsonify, request, Response
from services.medicamento.medicamento_service import MedicamentoService


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


# Stored in the existing registros_app JSON table: no migration needed.
def foto_medicamento(medicamento_id):
    from base64 import b64decode, b64encode
    from binascii import Error as Base64Error
    from extensions import db
    from models.medicamento.remedio import Remedio
    from models.paciente.registro_app import RegistroApp
    medicamento = db.session.get(Remedio, medicamento_id)
    if medicamento is None:
        return jsonify(erro='Medicamento não encontrado.'), 404
    recurso = f'medfoto:{medicamento_id}'
    registro = db.session.scalar(db.select(RegistroApp).where(
        RegistroApp.paciente_id == medicamento.paciente_id,
        RegistroApp.recurso == recurso,
    ).limit(1))
    if request.method == 'GET':
        if registro is None:
            return jsonify(erro='Sem foto cadastrada.'), 404
        try:
            foto = b64decode(registro.dados['foto_base64'], validate=True)
        except (KeyError, ValueError, Base64Error):
            return jsonify(erro='Arquivo da foto inválido.'), 500
        return Response(foto, mimetype=registro.dados['mime_type'],
                        headers={'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff'})
    if request.method == 'DELETE':
        if registro:
            if not registro.deletar():
                return jsonify(erro='Não foi possível remover a foto.'), 500
        return jsonify(medicamento.to_dict)

    dados = request.get_json(silent=True) or {}
    mime = dados.get('mime_type')
    base64_texto = dados.get('foto_base64')
    if mime not in {'image/jpeg', 'image/png', 'image/webp'} or not isinstance(base64_texto, str):
        return jsonify(erro='Formato de foto inválido.'), 400
    if len(base64_texto) > 3 * 1024 * 1024:
        return jsonify(erro='Foto muito grande (máximo 2 MB).'), 413
    try:
        foto = b64decode(base64_texto, validate=True)
    except (Base64Error, ValueError):
        return jsonify(erro='Imagem inválida.'), 400
    assinaturas = {
        'image/jpeg': lambda b: b.startswith(b'\xff\xd8\xff'),
        'image/png': lambda b: b.startswith(b'\x89PNG\r\n\x1a\n'),
        'image/webp': lambda b: b[:4] == b'RIFF' and b[8:12] == b'WEBP',
    }
    if not foto or len(foto) > 2 * 1024 * 1024 or not assinaturas[mime](foto):
        return jsonify(erro='Arquivo não é uma imagem válida de até 2 MB.'), 400
    payload = {'foto_base64': b64encode(foto).decode('ascii'), 'mime_type': mime}
    if registro is None:
        registro = RegistroApp.criar(medicamento.paciente_id, recurso, payload)
    else:
        registro = registro.atualizar(payload)
    if registro is None:
        return jsonify(erro='Não foi possível salvar a imagem.'), 500
    return jsonify(medicamento.to_dict)
