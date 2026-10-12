import datetime
from extensions import db
from ..user import Usuario


# Tabela de relacionamento entre Paciente e Responsavel


class Paciente(Usuario):
    """Usuario que possui responsaveis, medicamentos e sinais vitais."""

    __tablename__ = "pacientes"

    id = db.Column(
        db.Integer,
        primary_key=True
    )
    preferiencias = db.Column(db.Text, nullable = True)

    # Um paciente possui um cuidador; um cuidador pode acompanhar varios pacientes.
    cuidador_id = db.Column(
        db.Integer,
        db.ForeignKey("cuidadores.id"),
        nullable=True,
        index=True,
    )
    cuidador = db.relationship("Cuidador", back_populates="pacientes")

    # Responsável principal, disponível diretamente na tabela pacientes.
    # A relação muitos-para-muitos em ``responsaveis`` continua sendo usada
    # para os demais vínculos.
    responsavel_id = db.Column(
        db.Integer,
        db.ForeignKey("responsaveis.id"),
        nullable=True,
    )

    responsavel = db.relationship(
        "Responsavel",
        foreign_keys=[responsavel_id],
    )

    responsaveis = db.relationship(
        "Responsavel",
        secondary="paciente_responsavel",
        back_populates="pacientes"
    )

    remedios = db.relationship(
        "Remedio",
        back_populates="paciente",
        # Ao remover um paciente, remove tambem medicamentos que nao fazem sentido sem ele.
        cascade="all, delete-orphan",
        # A lista recebida pelo codigo ja vem em ordem alfabetica.
        order_by="Remedio.nome",
    )

    sinais_vitais = db.relationship(
        "SinalVital", back_populates="paciente", cascade="all, delete-orphan",
        order_by="SinalVital.data.desc()",
    )

    __mapper_args__ = {
        "polymorphic_identity": "paciente"
    }

    def vincular_cuidador(self, cuidador):
        try:
            self.cuidador_id = cuidador.id
            db.session.commit()
            return self
        except Exception:
            db.session.rollback()
            return None

    @classmethod
    def listar_por_cuidador(cls, cuidador_id):
        """Retorna todos os pacientes associados ao cuidador informado."""
        consulta = db.select(cls).where(cls.cuidador_id == cuidador_id).order_by(cls.name)
        return db.session.scalars(consulta).all()

    


class SinalVital(db.Model):
    """Registro pontual das medidas clinicas de um paciente."""
    __tablename__ = "sinais_vitais"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    data = db.Column(
        db.DateTime,
        default=datetime.datetime.now
    )
    paciente_id = db.Column(
        db.Integer, db.ForeignKey("pacientes.id"), nullable=False, index=True
    )
    paciente = db.relationship("Paciente", back_populates="sinais_vitais")
    freq_cardiaca = db.Column(db.String(30))
    saturacao = db.Column(db.String(30))
    pressao_art = db.Column(db.String(30))
    glicemia = db.Column(db.String(30))
    temperatura = db.Column(db.String(30))

    @property
    def to_dict(self):
        """Representacao segura para as respostas da API."""
        return {
            "id": self.id,
            "data": self.data.isoformat() if self.data else None,
            "freq_cardiaca": self.freq_cardiaca,
            "saturacao": self.saturacao,
            "pressao_art": self.pressao_art,
            "glicemia": self.glicemia,
            "temperatura": self.temperatura,
        }

    @classmethod
    def criar(cls, paciente_id, dados):
        sinal_vital = cls(paciente_id=paciente_id, **dados)
        return sinal_vital.salvar()

    def atualizar(self, dados):
        for campo in ("data", "freq_cardiaca", "saturacao", "pressao_art", "glicemia", "temperatura"):
            if campo in dados:
                setattr(self, campo, dados[campo])
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
