from flask import Blueprint
from controllers.relacionamento import solicitacoes_controller as controller

solicitacoesbp = Blueprint('solicitacoes', __name__)

@solicitacoesbp.get('/minha-conta/pacientes')
def meus_pacientes():
    return controller.meus_pacientes()

@solicitacoesbp.post('/minha-conta/pacientes')
def vincular_paciente():
    return controller.vincular_paciente()

@solicitacoesbp.route('/minha-conta/solicitacoes', methods=['GET', 'POST'])
def solicitacoes():
    return controller.solicitacoes()

@solicitacoesbp.patch('/minha-conta/solicitacoes/<int:id>')
def responder(id):
    return controller.responder(id)

@solicitacoesbp.route('/minha-conta', methods=['GET', 'PATCH'])
def minha_conta():
    return controller.minha_conta()

@solicitacoesbp.delete('/minha-conta')
def excluir_minha_conta():
    return controller.excluir_minha_conta()
