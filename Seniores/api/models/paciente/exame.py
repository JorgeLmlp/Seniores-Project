from extensions import db


class Exame(db.Model):
    """Exame solicitado ou realizado para um paciente."""

    __tablename__ = "exames"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    nome = db.Column(db.String(120), nullable=False)
    data = db.Column(db.String(20), nullable=False)
    laboratorio = db.Column(db.String(120), nullable=True)
    local = db.Column(db.String(255), nullable=True)
    observacoes = db.Column(db.String(500), nullable=True)
    documento_url = db.Column(db.String(500), nullable=True)
    documentos = db.relationship(
        "DocumentoExame",
        back_populates="exame",
        cascade="all, delete-orphan",
    )

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "nome": self.nome,
            "data": self.data,
            "laboratorio": self.laboratorio,
            "local": self.local,
            "observacoes": self.observacoes,
            "documento_url": self.documento_url,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.data)
        ).all()

    @classmethod
    def buscar_por_id(cls, exame_id):
        return db.session.get(cls, exame_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        exame = cls(paciente_id=paciente_id, **dados)
        return exame.salvar()

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
