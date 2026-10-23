from datetime import datetime, timezone

from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer

from extensions import app
from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


CLASSES_POR_TIPO = {
    "paciente": Paciente,
    "cuidador": Cuidador,
    "responsavel": Responsavel,
}
TOKEN_MAX_AGE = 8 * 60 * 60


def _serializer():
    return URLSafeTimedSerializer(app.config["SECRET_KEY"], salt="seniores-session")


def emitir_token(usuario):
    agora = int(datetime.now(timezone.utc).timestamp())
    return _serializer().dumps(
        {"id": usuario.id, "tipo": usuario.tipo, "emitido_em": agora}
    )


def ler_token(token):
    try:
        dados = _serializer().loads(token, max_age=TOKEN_MAX_AGE)
    except (BadSignature, SignatureExpired):
        return None
    tipo = str(dados.get("tipo") or "").lower()
    classe = CLASSES_POR_TIPO.get(tipo)
    usuario_id = dados.get("id")
    if classe is None or not isinstance(usuario_id, int):
        return None
    usuario = classe.buscar_por_id(usuario_id)
    if not usuario:
        return None
    return usuario
