from datetime import date, datetime
from zoneinfo import ZoneInfo
from flask import Blueprint, request, jsonify, g
from extensions import db
from models.medicamento.remedio import Remedio
from models.paciente.paciente import Paciente
from models.paciente.cuidados import AdministracaoMedicamento

dosesbp = Blueprint('doses', __name__)


class Dose(db.Model):
    __tablename__ = 'status_doses'
    medicamento_id = db.Column(db.Integer, db.ForeignKey('tbl_remedio.id', ondelete='CASCADE'), primary_key=True)
    data = db.Column(db.String(10), primary_key=True)
    horario = db.Column(db.String(5), primary_key=True)
    concluida = db.Column(db.Boolean, nullable=False, default=False)


def listar_alertas_atrasados(paciente_id, agora=None):
    """Monta alertas das doses de hoje que passaram do horário sem conclusão."""
    paciente = db.session.get(Paciente, paciente_id)
    if paciente is None:
        return None
    agora = agora or datetime.now(ZoneInfo('America/Sao_Paulo'))
    dia = agora.date().isoformat()
    medicamentos = db.session.scalars(
        db.select(Remedio).where(Remedio.paciente_id == paciente_id)
    ).all()
    ids = [medicamento.id for medicamento in medicamentos]
    doses = db.session.scalars(
        db.select(Dose).where(
            Dose.medicamento_id.in_(ids),
            Dose.data == dia,
        )
    ).all() if ids else []
    concluidas = {
        (dose.medicamento_id, dose.horario): dose.concluida for dose in doses
    }
    alertas = []
    for medicamento in medicamentos:
        for horario in medicamento.horarios or []:
            try:
                hora, minuto = map(int, horario.split(':'))
                previsto = agora.replace(
                    hour=hora, minute=minuto, second=0, microsecond=0
                )
            except (AttributeError, TypeError, ValueError):
                continue
            if previsto >= agora or concluidas.get((medicamento.id, horario)) is True:
                continue
            alertas.append({
                'id': f'dose-{medicamento.id}-{dia}-{horario}',
                'tipo': 'medicamento_atrasado',
                'titulo': 'Medicamento atrasado',
                'mensagem': (
                    f'A dose de {medicamento.nome} das {horario} '
                    'ainda não foi concluída.'
                ),
                'medicamento_id': medicamento.id,
                'medicamento': medicamento.nome,
                'horario': horario,
                'data': dia,
                'responsavel_notificado': paciente.responsavel_id is not None,
            })
    return sorted(alertas, key=lambda alerta: alerta['horario'])


@dosesbp.get('/pacientes/<int:paciente_id>/alertas-medicamentos')
def alertas_medicamentos(paciente_id):
    alertas = listar_alertas_atrasados(paciente_id)
    if alertas is None:
        return jsonify(erro='Paciente não encontrado.'), 404
    return jsonify(alertas)


@dosesbp.route('/medicamentos/<int:medicamento_id>/doses/<dia>', methods=['GET', 'PUT'])
def doses(medicamento_id, dia):
    medicamento = db.session.get(Remedio, medicamento_id)
    if not medicamento:
        return jsonify(erro='Medicamento não encontrado.'), 404
    try:
        date.fromisoformat(dia)
    except ValueError:
        return jsonify(erro='Data inválida.'), 400
    if request.method == 'PUT':
        dados = request.get_json(silent=True) or {}
        horario = dados.get('horario')
        if horario not in (medicamento.horarios or []) or not isinstance(dados.get('concluida'), bool):
            return jsonify(erro='Horário ou status inválido.'), 400
        dose = db.session.get(Dose, (medicamento_id, dia, horario))
        if dose is None:
            dose = Dose(medicamento_id=medicamento_id, data=dia, horario=horario)
            db.session.add(dose)
        from datetime import time as horario_time
        try:
            hora, minuto = map(int, horario.split(':'))
            horario_previsto = datetime.combine(date.fromisoformat(dia), horario_time(hora, minuto))
        except (ValueError, TypeError):
            return jsonify(erro='Horário inválido.'), 400
        # Single matching record for this scheduled dose; repeated PUT must not
        # duplicate administrations. Other independent administrations are preserved.
        administracao = db.session.scalar(db.select(AdministracaoMedicamento).where(
            AdministracaoMedicamento.paciente_id == medicamento.paciente_id,
            AdministracaoMedicamento.medicamento_id == medicamento_id,
            AdministracaoMedicamento.horario_previsto == horario_previsto,
        ).order_by(AdministracaoMedicamento.id.desc()))
        if dados['concluida']:
            observacao = dados.get('observacao', '')
            if not isinstance(observacao, str) or len(observacao) > 1000:
                return jsonify(erro='Observação inválida (limite de 1000 caracteres).'), 400
            if administracao is None:
                administracao = AdministracaoMedicamento(
                    paciente_id=medicamento.paciente_id,
                    medicamento_id=medicamento_id,
                    horario_previsto=horario_previsto,
                )
                db.session.add(administracao)
            administracao.confirmado_por = getattr(g.get('usuario', None), 'name', 'Usuário autenticado')
            administracao.administrado_em = datetime.now(ZoneInfo('America/Sao_Paulo')).replace(tzinfo=None)
            administracao.observacao = observacao.strip() or None
        elif administracao is not None:
            # Undo applies only to the unique scheduled administration.
            db.session.delete(administracao)
        dose.concluida = dados['concluida']
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return jsonify(erro='Não foi possível salvar a administração.'), 500
    registros = db.session.scalars(db.select(Dose).where(Dose.medicamento_id == medicamento_id, Dose.data == dia))
    return jsonify({d.horario: d.concluida for d in registros})
