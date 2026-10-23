from extensions import db


class Gasto(db.Model):
    """Gasto registrado para um paciente."""

    __tablename__ = "gastos"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    descricao = db.Column(db.String(160), nullable=False)
    valor = db.Column(db.Float, nullable=False)
    data = db.Column(db.String(20), nullable=False)
    categoria = db.Column(db.String(80), nullable=True)
    tipo = db.Column(db.String(80), nullable=True)
    observacoes = db.Column(db.String(500), nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "descricao": self.descricao,
            "valor": self.valor,
            "data": self.data,
            "categoria": self.categoria,
            "tipo": self.tipo,
            "observacoes": self.observacoes,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.data.desc())
        ).all()

    @classmethod
    def buscar_por_id(cls, gasto_id):
        return db.session.get(cls, gasto_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        gasto = cls(paciente_id=paciente_id, **dados)
        return gasto.salvar()

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
