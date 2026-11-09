def foto_medicamento(medicamento_id, metodo, dados):
    from base64 import b64decode, b64encode
    from binascii import Error as Base64Error
    from repositories import medicamento_repository, paciente_repository
    from models.paciente.registro_app import RegistroApp
    medicamento = medicamento_repository.buscar_por_id(medicamento_id)
    if medicamento is None:
        return ({'erro': 'Medicamento não encontrado.'}, 404)
    recurso = f'medfoto:{medicamento_id}'
    registros = paciente_repository.listar_registros_app(medicamento.paciente_id, recurso)
    registro = registros[0] if registros else None
    if metodo == 'GET':
        if registro is None:
            return ({'erro': 'Sem foto cadastrada.'}, 404)
        try:
            foto = b64decode(registro.dados['foto_base64'], validate=True)
        except (KeyError, ValueError, Base64Error):
            return ({'erro': 'Arquivo da foto inválido.'}, 500)
        return ((foto, registro.dados['mime_type']), 200)
    if metodo == 'DELETE':
        if registro:
            if not registro.deletar():
                return ({'erro': 'Não foi possível remover a foto.'}, 500)
        return medicamento.to_dict
    mime = dados.get('mime_type')
    base64_texto = dados.get('foto_base64')
    if mime not in {'image/jpeg', 'image/png', 'image/webp'} or not isinstance(base64_texto, str):
        return ({'erro': 'Formato de foto inválido.'}, 400)
    if len(base64_texto) > 3 * 1024 * 1024:
        return ({'erro': 'Foto muito grande (máximo 2 MB).'}, 413)
    try:
        foto = b64decode(base64_texto, validate=True)
    except (Base64Error, ValueError):
        return ({'erro': 'Imagem inválida.'}, 400)
    assinaturas = {'image/jpeg': lambda b: b.startswith(b'\xff\xd8\xff'), 'image/png': lambda b: b.startswith(b'\x89PNG\r\n\x1a\n'), 'image/webp': lambda b: b[:4] == b'RIFF' and b[8:12] == b'WEBP'}
    if not foto or len(foto) > 2 * 1024 * 1024 or (not assinaturas[mime](foto)):
        return ({'erro': 'Arquivo não é uma imagem válida de até 2 MB.'}, 400)
    payload = {'foto_base64': b64encode(foto).decode('ascii'), 'mime_type': mime}
    if registro is None:
        registro = RegistroApp.criar(medicamento.paciente_id, recurso, payload)
    else:
        registro = registro.atualizar(payload)
    if registro is None:
        return ({'erro': 'Não foi possível salvar a imagem.'}, 500)
    return medicamento.to_dict
