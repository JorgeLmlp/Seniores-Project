from datetime import datetime

from extensions import db
from models.medicamento.remedio import Remedio
from models.paciente.cuidados import (
    AdministracaoMedicamento, ContatoEmergencia, DietaRestricao, ExameDocumento,
    Incidente,
)
from models.paciente.diario_saude import DiarioSaude
from models.paciente.estoque import Estoque
from models.paciente.paciente import Paciente, SinalVital
from models.paciente.registro_app import RegistroApp


def _listar(modelo, paciente_id, campo_data=None, inicio=None, fim=None, ordem=None):
    consulta = db.select(modelo).where(modelo.paciente_id == paciente_id)
    if campo_data is not None and inicio is not None:
        consulta = consulta.where(campo_data >= inicio, campo_data < fim)
    if ordem is not None:
        consulta = consulta.order_by(ordem)
    return db.session.scalars(consulta).all()


def _registro_app_no_mes(registro, inicio, fim):
    valor = registro.dados.get("dataHora") if isinstance(registro.dados, dict) else None
    if not valor:
        return inicio <= registro.data_criacao < fim
    try:
        data = datetime.fromisoformat(valor.replace("Z", "+00:00")).replace(tzinfo=None)
        return inicio <= data < fim
    except (AttributeError, ValueError):
        return False


def consultar_historico_mensal(paciente_id, ano, mes):
    paciente = db.session.get(Paciente, paciente_id)
    if not paciente:
        return None
    inicio = datetime(ano, mes, 1)
    fim = datetime(ano + (mes == 12), 1 if mes == 12 else mes + 1, 1)
    registros_app = db.session.scalars(
        db.select(RegistroApp).where(
            RegistroApp.paciente_id == paciente_id,
            RegistroApp.recurso.in_(("consultas", "exames")),
        )
    ).all()
    return {
        "paciente": paciente,
        "periodo": {"ano": ano, "mes": mes, "inicio": inicio, "fim": fim},
        # Medicamentos, dieta, contatos e estoque sao o retrato vigente no periodo do relatorio.
        "medicamentos": _listar(Remedio, paciente_id, ordem=Remedio.nome),
        "administracoes": _listar(AdministracaoMedicamento, paciente_id, AdministracaoMedicamento.administrado_em, inicio, fim, AdministracaoMedicamento.administrado_em),
        "sinais_vitais": _listar(SinalVital, paciente_id, SinalVital.data, inicio, fim, SinalVital.data),
        "diarios": _listar(DiarioSaude, paciente_id, DiarioSaude.data_criacao, inicio, fim, DiarioSaude.data_criacao),
        "incidentes": _listar(Incidente, paciente_id, Incidente.data_hora, inicio, fim, Incidente.data_hora),
        "consultas": [r for r in registros_app if r.recurso == "consultas" and _registro_app_no_mes(r, inicio, fim)],
        "exames_agendados": [r for r in registros_app if r.recurso == "exames" and _registro_app_no_mes(r, inicio, fim)],
        "documentos_exames": _listar(ExameDocumento, paciente_id, ExameDocumento.data_criacao, inicio, fim, ExameDocumento.data_criacao),
        "dietas": _listar(DietaRestricao, paciente_id, ordem=DietaRestricao.data_criacao.desc()),
        "contatos": _listar(ContatoEmergencia, paciente_id, ordem=ContatoEmergencia.nome),
        "estoque": _listar(Estoque, paciente_id, ordem=Estoque.nome),
    }
