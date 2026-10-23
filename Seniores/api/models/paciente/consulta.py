from extensions import db


class Consulta(db.Model):
    """Consulta agendada para um paciente."""

    __tablename__ = "consultas"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    titulo = db.Column(db.String(120), nullable=False)
    especialidade = db.Column(db.String(100), nullable=True)
    profissional = db.Column(db.String(120), nullable=True)
    data = db.Column(db.String(20), nullable=False)
    hora = db.Column(db.String(10), nullable=True)
    local = db.Column(db.String(255), nullable=True)
    telefone = db.Column(db.String(30), nullable=True)
    observacoes = db.Column(db.String(500), nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "titulo": self.titulo,
            "especialidade": self.especialidade,
            "profissional": self.profissional,
            "data": self.data,
            "hora": self.hora,
            "local": self.local,
            "telefone": self.telefone,
            "observacoes": self.observacoes,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.data, cls.hora)
        ).all()

    @classmethod
    def buscar_por_id(cls, consulta_id):
        return db.session.get(cls, consulta_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        consulta = cls(paciente_id=paciente_id, **dados)
        return consulta.salvar()

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
