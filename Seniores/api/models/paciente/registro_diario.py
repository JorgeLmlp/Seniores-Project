from extensions import db


class RegistroDiario(db.Model):
    """Registro diario de evolucao de um paciente."""

    __tablename__ = "registros_diarios"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    data = db.Column(db.String(30), nullable=False)
    humor = db.Column(db.Float, nullable=True)
    dor = db.Column(db.Float, nullable=True)
    apetite = db.Column(db.Float, nullable=True)
    mobilidade = db.Column(db.Float, nullable=True)
    observacoes = db.Column(db.String(1000), nullable=True)
    duvidas = db.Column(db.String(1000), nullable=True)
    total_incidentes = db.Column(db.Integer, nullable=False, default=0)
    tendencia = db.Column(db.String(80), nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "data": self.data,
            "humor": self.humor,
            "dor": self.dor,
            "apetite": self.apetite,
            "mobilidade": self.mobilidade,
            "observacoes": self.observacoes,
            "duvidas": self.duvidas,
            "total_incidentes": self.total_incidentes,
            "tendencia": self.tendencia,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.data.desc())
        ).all()

    @classmethod
    def buscar_por_id(cls, registro_id):
        return db.session.get(cls, registro_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        registro = cls(paciente_id=paciente_id, **dados)
        return registro.salvar()

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
