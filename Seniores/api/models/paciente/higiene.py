from extensions import db


class Higiene(db.Model):
    """Registro de uma rotina/checklist de higiene do paciente."""

    __tablename__ = "higienes"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    tipo = db.Column(db.String(80), nullable=False)
    data_hora = db.Column(db.String(30), nullable=False)
    itens = db.Column(db.JSON, nullable=False, default=dict)
    observacoes = db.Column(db.String(500), nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "tipo": self.tipo,
            "data_hora": self.data_hora,
            "itens": self.itens or {},
            "observacoes": self.observacoes or "",
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls)
            .where(cls.paciente_id == paciente_id)
            .order_by(cls.data_hora.desc())
        ).all()

    @classmethod
    def buscar_por_id(cls, higiene_id):
        return db.session.get(cls, higiene_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        higiene = cls(paciente_id=paciente_id, **dados)
        return higiene.salvar()

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
