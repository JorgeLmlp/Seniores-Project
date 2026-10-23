from extensions import db


class Dieta(db.Model):
    """Plano alimentar e restrições alimentares do paciente."""

    __tablename__ = "dietas"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    tipo = db.Column(db.String(80), nullable=False)
    data_inicio = db.Column(db.String(30), nullable=False)
    descricao = db.Column(db.String(1000), nullable=False)
    restricoes = db.Column(db.String(1000), nullable=True)
    observacoes = db.Column(db.String(1000), nullable=True)
    ativa = db.Column(db.Boolean, nullable=False, default=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "tipo": self.tipo,
            "data_inicio": self.data_inicio,
            "descricao": self.descricao,
            "restricoes": self.restricoes or "",
            "observacoes": self.observacoes or "",
            "ativa": self.ativa,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls)
            .where(cls.paciente_id == paciente_id)
            .order_by(cls.ativa.desc(), cls.data_inicio.desc())
        ).all()

    @classmethod
    def buscar_por_id(cls, dieta_id):
        return db.session.get(cls, dieta_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        dieta = cls(paciente_id=paciente_id, **dados)
        return dieta.salvar()

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
