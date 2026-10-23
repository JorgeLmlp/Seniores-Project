from extensions import db


class Lesao(db.Model):
    """Prontuário de uma lesão e sua evolução clínica."""

    __tablename__ = "lesoes"

    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )
    localizacao = db.Column(db.String(120), nullable=False)
    data_inicio = db.Column(db.String(30), nullable=False)
    descricao = db.Column(db.String(1000), nullable=False)
    evolucao = db.Column(db.String(2000), nullable=True)
    foto_nome = db.Column(db.String(255), nullable=True)
    foto_nome_armazenado = db.Column(db.String(255), nullable=True)
    foto_mime = db.Column(db.String(80), nullable=True)

    @property
    def to_dict(self):
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "localizacao": self.localizacao,
            "data_inicio": self.data_inicio,
            "descricao": self.descricao,
            "evolucao": self.evolucao or "",
            "foto_nome": self.foto_nome,
        }

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls)
            .where(cls.paciente_id == paciente_id)
            .order_by(cls.data_inicio.desc())
        ).all()

    @classmethod
    def buscar_por_id(cls, lesao_id):
        return db.session.get(cls, lesao_id)

    @classmethod
    def criar(cls, paciente_id, dados):
        lesao = cls(paciente_id=paciente_id, **dados)
        return lesao.salvar()

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
