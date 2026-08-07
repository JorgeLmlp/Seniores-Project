from extensions import db
from datetime import datetime

class Base_info(db.Model):
    __abstract__ = True
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.ForeignKey('paciente.id'))
    data_criacao = db.Column(db.DateTime, default=datetime.now)
    data_alteracao = db.Column(db.DateTime, nullable=True)

    def criar(self):
        """Salva um novo registro no banco de dados"""
        db.session.add(self)
        db.session.commit()

    def excluir_concluir(self):
        """Remove o registro do banco de dados"""
        db.session.delete(self)
        db.session.commit()

    def alterar(self):
        """Atualiza a data de alteração e salva as modificações"""
        self.data_alteracao = datetime.now()
        db.session.add(self)
        db.session.commit()