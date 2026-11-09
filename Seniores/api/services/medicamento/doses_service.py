from datetime import date, datetime
from zoneinfo import ZoneInfo
from models.medicamento.dose import Dose
from models import transacao
from repositories import fluxo_repository as repo
from models.medicamento.remedio import Remedio
from models.paciente.paciente import Paciente
from models.paciente.cuidados import AdministracaoMedicamento


def listar_alertas_atrasados(paciente_id, agora=None):
    """Monta alertas das doses de hoje que passaram do horário sem conclusão."""
    paciente = repo.buscar(Paciente, paciente_id)
    if paciente is None:
        return None
    agora = agora or datetime.now(ZoneInfo('America/Sao_Paulo'))
    dia = agora.date().isoformat()
    medicamentos = repo.medicamentos(paciente_id)
    ids = [medicamento.id for medicamento in medicamentos]
    doses = repo.doses_do_dia(ids, dia)
    concluidas = {(dose.medicamento_id, dose.horario): dose.concluida for dose in doses}
    alertas = []
    for medicamento in medicamentos:
        for horario in medicamento.horarios or []:
            try:
                hora, minuto = map(int, horario.split(':'))
                previsto = agora.replace(hour=hora, minute=minuto, second=0, microsecond=0)
            except (AttributeError, TypeError, ValueError):
                continue
            if previsto >= agora or concluidas.get((medicamento.id, horario)) is True:
                continue
            alertas.append({'id': f'dose-{medicamento.id}-{dia}-{horario}', 'tipo': 'medicamento_atrasado', 'titulo': 'Medicamento atrasado', 'mensagem': f'A dose de {medicamento.nome} das {horario} ainda não foi concluída.', 'medicamento_id': medicamento.id, 'medicamento': medicamento.nome, 'horario': horario, 'data': dia, 'responsavel_notificado': paciente.responsavel_id is not None})
    return sorted(alertas, key=lambda alerta: alerta['horario'])


def alertas_medicamentos(paciente_id, usuario_atual, metodo, dados):
    alertas = listar_alertas_atrasados(paciente_id)
    if alertas is None:
        return ({'erro': 'Paciente não encontrado.'}, 404)
    return alertas


def doses(medicamento_id, dia, usuario_atual, metodo, dados):
    medicamento = repo.buscar(Remedio, medicamento_id)
    if not medicamento:
        return ({'erro': 'Medicamento não encontrado.'}, 404)
    try:
        date.fromisoformat(dia)
    except ValueError:
        return ({'erro': 'Data inválida.'}, 400)
    if metodo == 'PUT':
        horario = dados.get('horario')
        if horario not in (medicamento.horarios or []) or not isinstance(dados.get('concluida'), bool):
            return ({'erro': 'Horário ou status inválido.'}, 400)
        dose = repo.buscar(Dose, (medicamento_id, dia, horario))
        if dose is None:
            dose = Dose(medicamento_id=medicamento_id, data=dia, horario=horario)
            transacao.adicionar(dose)
        from datetime import time as horario_time
        try:
            hora, minuto = map(int, horario.split(':'))
            horario_previsto = datetime.combine(date.fromisoformat(dia), horario_time(hora, minuto))
        except (ValueError, TypeError):
            return ({'erro': 'Horário inválido.'}, 400)
        administracao = repo.administracao(medicamento.paciente_id, medicamento_id, horario_previsto)
        if dados['concluida']:
            observacao = dados.get('observacao', '')
            if not isinstance(observacao, str) or len(observacao) > 1000:
                return ({'erro': 'Observação inválida (limite de 1000 caracteres).'}, 400)
            if administracao is None:
                administracao = AdministracaoMedicamento(paciente_id=medicamento.paciente_id, medicamento_id=medicamento_id, horario_previsto=horario_previsto)
                transacao.adicionar(administracao)
            administracao.confirmado_por = getattr(usuario_atual, 'name', 'Usuário autenticado')
            administracao.administrado_em = datetime.now(ZoneInfo('America/Sao_Paulo')).replace(tzinfo=None)
            administracao.observacao = observacao.strip() or None
        elif administracao is not None:
            transacao.remover(administracao)
        dose.concluida = dados['concluida']
        try:
            transacao.confirmar()
        except Exception:
            transacao.cancelar()
            return ({'erro': 'Não foi possível salvar a administração.'}, 500)
    registros = repo.doses_do_dia([medicamento_id], dia)
    return {d.horario: d.concluida for d in registros}
