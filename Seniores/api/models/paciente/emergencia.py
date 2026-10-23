from datetime import datetime

from extensions import db


class ContatoEmergencia(db.Model):
    """Contato que pode ser acionado em uma emergencia."""

    __tablename__ = "contatos_emergencia"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    nome = db.Column(db.String(120), nullable=False)
    telefone = db.Column(db.String(30), nullable=False)
    parentesco = db.Column(db.String(80), nullable=True)
    observacoes = db.Column(db.String(300), nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "nome": self.nome,
            "telefone": self.telefone,
            "parentesco": self.parentesco,
            "observacoes": self.observacoes,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.nome)
        ).all()

    @classmethod
    def buscar_por_id(cls, contato_id):
        return db.session.get(cls, contato_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        contato = cls(paciente_id=paciente_id, **dados)
        return contato.salvar()

    def atualizar(self, dados):
        for campo, valor in dados.items():
            setattr(self, campo, valor)
        return self.salvar()

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


class AlertaEmergencia(db.Model):
    """Alerta de emergencia emitido pelo paciente."""

    __tablename__ = "alertas_emergencia"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    data_hora = db.Column(db.DateTime, default=datetime.now, nullable=False)
    localizacao = db.Column(db.String(255), nullable=True)
    observacoes = db.Column(db.String(500), nullable=True)
    status = db.Column(db.String(30), nullable=False, default="aberto")

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "data_hora": self.data_hora.isoformat() if self.data_hora else None,
            "localizacao": self.localizacao,
            "observacoes": self.observacoes,
            "status": self.status,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.data_hora.desc())
        ).all()

    @classmethod
    def buscar_por_id(cls, alerta_id):
        return db.session.get(cls, alerta_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        alerta = cls(paciente_id=paciente_id, **dados)
        return alerta.salvar()

    def atualizar(self, dados):
        for campo, valor in dados.items():
            setattr(self, campo, valor)
        return self.salvar()

    def salvar(self):
        try:
            db.session.add(self)
            db.session.commit()
            return self
        except Exception:
            db.session.rollback()
            return None
