from datetime import datetime

from extensions import db

class Base_info(db.Model):
    """Campos e operacoes CRUD comuns aos registros de um paciente."""

    __abstract__ = True
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False, index=True)
    data_criacao = db.Column(db.DateTime, default=datetime.now)
    data_alteracao = db.Column(db.DateTime, nullable=True)

    @classmethod
    def criar(cls, paciente_id, dados):
        return cls(paciente_id=paciente_id, **dados).salvar()

    def salvar(self):
        try:
            db.session.add(self)
            db.session.commit()
            return self
        except Exception:
            db.session.rollback()
            return None

    def deletar(self):
        try:
            db.session.delete(self)
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            return False

    def atualizar(self, dados, campos_editaveis):
        for campo in campos_editaveis:
            if campo in dados:
                setattr(self, campo, dados[campo])
        self.data_alteracao = datetime.now()
        return self.salvar()
