from datetime import date
from flask import Blueprint, request, jsonify
from extensions import db
from models.medicamento.remedio import Remedio

dosesbp = Blueprint('doses', __name__)


class Dose(db.Model):
    __tablename__ = 'status_doses'
    medicamento_id = db.Column(db.Integer, db.ForeignKey('tbl_remedio.id', ondelete='CASCADE'), primary_key=True)
    data = db.Column(db.String(10), primary_key=True)
    horario = db.Column(db.String(5), primary_key=True)
    concluida = db.Column(db.Boolean, nullable=False, default=False)


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
        dose.concluida = dados['concluida']
        db.session.commit()
    registros = db.session.scalars(db.select(Dose).where(Dose.medicamento_id == medicamento_id, Dose.data == dia))
    return jsonify({d.horario: d.concluida for d in registros})
