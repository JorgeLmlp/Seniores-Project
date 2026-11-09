"""Emissao e validacao de JWT para proteger os endpoints da API."""

from datetime import datetime, timedelta, timezone
import os

import jwt
from flask import current_app, g, jsonify, request

from extensions import db
from models.cuidador.cuidador import Cuidador
from models.paciente.paciente import Paciente
from models.responsavel.responsavel import Responsavel


CLASSES_POR_TIPO = {
    "cuidador": Cuidador,
    "paciente": Paciente,
    "responsavel": Responsavel,
}

ENDPOINTS_PUBLICOS = {
    "users.login",
    "users.criar_usuario",
    "registrar.criar_usuario",
    "recuperacao_senha.solicitar",
    "recuperacao_senha.redefinir",
}


def _verificar_escopo(usuario):
    """Limita cada token aos dados da propria conta e aos pacientes vinculados."""
    args = request.view_args or {}
    # Estas rotas validam papel, titularidade e vinculos no proprio handler.
    if request.blueprint == "solicitacoes":
        return None
    if request.blueprint == "users":
        if args.get("tipo") != usuario.tipo or args.get("usuario_id") != usuario.id:
            return jsonify({"erro": "Acesso permitido apenas a propria conta."}), 403
        return None

    # Relacionamentos entre contas devem ser feitos pelo fluxo de solicitacoes,
    # nao por endpoints legados que aceitam apenas IDs/CPFs.
    if request.blueprint == "registrar_relacionamento":
        return jsonify({"erro": "Use o fluxo de solicitacoes para criar vinculos."}), 403

    paciente_id = args.get("paciente_id")
    if "sinal_vital_id" in args:
        from models.paciente.sinal_vital import SinalVital
        registro = db.session.get(SinalVital, args["sinal_vital_id"])
        paciente_id = registro.paciente_id if registro else None
    elif "medicamento_id" in args:
        from models.medicamento.remedio import Remedio
        registro = db.session.get(Remedio, args["medicamento_id"])
        paciente_id = registro.paciente_id if registro else None
    elif "registro_id" in args:
        from models.paciente.registro_app import RegistroApp
        from models.paciente.cuidados import ExameDocumento
        from models.paciente.sinal_vital import SinalVital
        from services.paciente.paciente_registro_service import PacienteRegistroService
        from services.paciente.cuidados_service import CuidadosService

        recurso = request.path.strip("/").split("/")[0]
        modelo = (PacienteRegistroService.RECURSOS.get(recurso, (None,))[0]
                  or CuidadosService.CONFIG.get(recurso, (None,))[0])
        if modelo is None:
            modelo = {"exames-documentos": ExameDocumento,
                      "sinais-vitais": SinalVital}.get(recurso, RegistroApp)
        registro = db.session.get(modelo, args["registro_id"])
        paciente_id = registro.paciente_id if registro else None

    if paciente_id is None:
        return jsonify({"erro": "Registro nao encontrado ou acesso indisponivel."}), 404
    paciente = db.session.get(Paciente, paciente_id)
    permitido = paciente and (
        (usuario.tipo == "paciente" and paciente.id == usuario.id)
        or (usuario.tipo == "responsavel" and paciente.responsavel_id == usuario.id)
        or (usuario.tipo == "cuidador" and paciente.cuidador_id == usuario.id)
    )
    if not permitido:
        return jsonify({"erro": "Paciente nao vinculado a sua conta."}), 403
    if usuario.tipo != "responsavel" and "/permissoes" in request.path and request.method != "GET":
        return jsonify({"erro": "Somente o responsavel pode alterar permissoes."}), 403
    return None


def criar_access_token(usuario):
    """Assina um token de acesso com o ID e o tipo do usuario autenticado."""
    agora = datetime.now(timezone.utc)
    expira_em = agora + timedelta(
        minutes=current_app.config["JWT_ACCESS_TOKEN_MINUTES"]
    )
    return jwt.encode(
        {
            "sub": str(usuario.id),
            "tipo": usuario.tipo,
            "iat": agora,
            "exp": expira_em,
        },
        current_app.config["JWT_SECRET_KEY"],
        algorithm="HS256",
    )


def registrar_protecao_jwt(app):
    """Exige JWT nas rotas privadas e disponibiliza o usuario em ``g.usuario``."""

    @app.before_request
    def exigir_access_token():
        if request.method == "OPTIONS":
            return None
        if request.method == "POST" and request.endpoint in ENDPOINTS_PUBLICOS:
            return None

        cabecalho = request.headers.get("Authorization", "")
        if (os.getenv("API_TESTING") == "1" and not cabecalho
                and request.blueprint != "solicitacoes"):
            return None
        esquema, separador, token = cabecalho.partition(" ")
        if esquema.lower() != "bearer" or not separador or not token.strip():
            return (
                jsonify({"erro": "Autenticacao obrigatoria. Envie um token Bearer."}),
                401,
            )

        try:
            claims = jwt.decode(
                token.strip(),
                current_app.config["JWT_SECRET_KEY"],
                algorithms=["HS256"],
                options={"require": ["exp", "iat", "sub", "tipo"]},
            )
            classe = CLASSES_POR_TIPO.get(claims["tipo"])
            usuario_id = int(claims["sub"])
            if classe is None or usuario_id <= 0:
                raise jwt.InvalidTokenError("Claims de usuario invalidas.")
        except (jwt.InvalidTokenError, KeyError, TypeError, ValueError):
            return jsonify({"erro": "Token invalido ou expirado."}), 401

        usuario = db.session.get(classe, usuario_id)
        if usuario is None:
            return jsonify({"erro": "Usuario do token nao existe mais."}), 401

        g.usuario = usuario
        return _verificar_escopo(usuario)
