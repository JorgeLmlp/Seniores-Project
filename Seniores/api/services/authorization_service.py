from flask import g, request
from extensions import db


def _paciente_por_requisicao():
    """Resolve o paciente alvo de rotas de lista e de recursos filhos."""
    from models.paciente.administracao_medicamento import AdministracaoMedicamento
    from models.paciente.comunicado import Comunicado
    from models.paciente.consulta import Consulta
    from models.paciente.dieta import Dieta
    from models.paciente.documento_exame import DocumentoExame
    from models.paciente.emergencia import AlertaEmergencia, ContatoEmergencia
    from models.paciente.exame import Exame
    from models.paciente.estoque import ItemEstoque
    from models.paciente.gasto import Gasto
    from models.paciente.higiene import Higiene
    from models.paciente.incidente import Incidente
    from models.paciente.lesao import Lesao
    from models.paciente.notificacao import Notificacao
    from models.paciente.registro_diario import RegistroDiario
    from models.paciente.remedio import Remedio
    from models.paciente.paciente import Paciente

    args = request.view_args or {}
    paciente_id = args.get("paciente_id")
    if paciente_id is not None:
        return Paciente.buscar_por_id(paciente_id)

    modelos = {
        "medicamento_id": Remedio,
        "administracao_id": AdministracaoMedicamento,
        "consulta_id": Consulta,
        "exame_id": Exame,
        "item_id": ItemEstoque,
        "incidente_id": Incidente,
        "contato_id": ContatoEmergencia,
        "alerta_id": AlertaEmergencia,
        "registro_id": RegistroDiario,
        "gasto_id": Gasto,
        "notificacao_id": Notificacao,
        "comunicado_id": Comunicado,
        "documento_id": DocumentoExame,
        "higiene_id": Higiene,
        "lesao_id": Lesao,
        "dieta_id": Dieta,
    }
    for argumento, modelo in modelos.items():
        if argumento not in args:
            continue
        registro = db.session.get(modelo, args[argumento])
        if registro is None:
            return None
        if argumento == "administracao_id":
            medicamento = db.session.get(Remedio, registro.medicamento_id)
            return Paciente.buscar_por_id(medicamento.paciente_id) if medicamento else None
        if argumento == "documento_id":
            exame = db.session.get(Exame, registro.exame_id)
            return Paciente.buscar_por_id(exame.paciente_id) if exame else None
        return Paciente.buscar_por_id(registro.paciente_id)

    if request.path == "/historico/email":
        dados = request.get_json(silent=True) or {}
        if dados.get("paciente_id") is not None:
            return Paciente.buscar_por_id(dados["paciente_id"])
    return None


def _usuario_tem_acesso(paciente):
    if paciente is None:
        return False
    if g.tipo_usuario == "paciente":
        return paciente.id == g.usuario_id
    if g.tipo_usuario == "cuidador":
        return paciente.cuidador_id == g.usuario_id
    if g.tipo_usuario == "responsavel":
        return (
            paciente.responsavel_id == g.usuario_id
            or any(item.id == g.usuario_id for item in paciente.responsaveis)
        )
    return False


def autorizar_requisicao():
    """Aplica escopo por paciente e protege conta/relacionamentos."""
    if request.path == "/users/" and request.method == "GET":
        tipo = request.args.get("tipo")
        cuidador_id = request.args.get("cuidador_id")
        responsavel_id = request.args.get("responsavel_id")
        if cuidador_id or responsavel_id:
            esperado = str(g.usuario_id)
            if g.tipo_usuario == "cuidador" and cuidador_id == esperado:
                return None
            if g.tipo_usuario == "responsavel" and responsavel_id == esperado:
                return None
            return {"erro": "Acesso negado"}, 403
        if tipo == "paciente":
            return {"erro": "Filtro de pacientes vinculados obrigatorio"}, 403

    args = request.view_args or {}
    if "usuario_id" in args:
        if args["usuario_id"] != g.usuario_id:
            return {"erro": "Acesso negado"}, 403
        return None

    if request.path.startswith("/registrar_relacionamento") or request.path.startswith(
        "/relacionamentos/"
    ):
        if g.tipo_usuario != "paciente":
            return {"erro": "Somente o paciente pode gerenciar vinculos"}, 403
        return None

    if (
        request.method != "GET"
        and request.path.startswith("/pacientes/")
        and ("/cuidador" in request.path or "/responsaveis" in request.path)
        and g.tipo_usuario != "paciente"
    ):
        return {"erro": "Somente o paciente pode gerenciar vinculos"}, 403

    paciente = _paciente_por_requisicao()
    if paciente is not None and not _usuario_tem_acesso(paciente):
        return {"erro": "Paciente nao vinculado a esta sessao"}, 403
    if paciente is None and request.path == "/historico/email":
        return {"erro": "Paciente nao encontrado"}, 404
    return None

