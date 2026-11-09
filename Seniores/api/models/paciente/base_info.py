"""Model base com persistencia comum aos registros ligados a pacientes."""

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
        """Instancia o model concreto e persiste a nova linha."""
        return cls(paciente_id=paciente_id, **dados).salvar()

    def salvar(self):
        """Confirma a transacao e restaura a sessao em caso de erro."""
        try:
            db.session.add(self)
            db.session.commit()
            return self
        except Exception:
            db.session.rollback()
            return None

    def deletar(self):
        """Remove a linha e devolve se a transacao foi concluida."""
        try:
            db.session.delete(self)
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            return False

    def atualizar(self, dados, campos_editaveis):
        """Aplica somente campos autorizados antes de persistir."""
        for campo in campos_editaveis:
            if campo in dados:
                setattr(self, campo, dados[campo])
        self.data_alteracao = datetime.now()
        return self.salvar()
