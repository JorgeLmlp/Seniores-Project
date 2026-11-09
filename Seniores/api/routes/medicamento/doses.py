from flask import Blueprint
from controllers.medicamento import doses_controller as controller

dosesbp = Blueprint('doses', __name__)

@dosesbp.get('/pacientes/<int:paciente_id>/alertas-medicamentos')
def alertas_medicamentos(paciente_id):
    return controller.alertas_medicamentos(paciente_id)

@dosesbp.route('/medicamentos/<int:medicamento_id>/doses/<dia>', methods=['GET', 'PUT'])
def doses(medicamento_id, dia):
    return controller.doses(medicamento_id, dia)
