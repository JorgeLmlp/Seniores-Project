from extensions import db
from datetime import datetime
from models.paciente.paciente import Paciente
from models.cuidador.cuidador import Cuidador
from models.responsavel.responsavel import Responsavel

class Solicitacao(db.Model):
    __tablename__ = 'solicitacoes_cuidado'
    id = db.Column(db.Integer, primary_key=True)
    responsavel_id = db.Column(db.Integer, db.ForeignKey('responsaveis.id'), nullable=False)
    cuidador_id = db.Column(db.Integer, db.ForeignKey('cuidadores.id'), nullable=False)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    status = db.Column(db.String(15), nullable=False, default='pendente')
    criada_em = db.Column(db.DateTime, default=datetime.now)

    def json(self):
        def resumo(classe, id):
            pessoa = db.session.get(classe, id)
            return {
                'id': pessoa.id,
                'nome': pessoa.name,
                'telefone': pessoa.phoneNumber,
                'email': pessoa.email,
            } if pessoa else None
        return {'id': self.id, 'status': self.status,
                'responsavel': resumo(Responsavel, self.responsavel_id),
                'paciente': resumo(Paciente, self.paciente_id),
                'cuidador': resumo(Cuidador, self.cuidador_id)}
