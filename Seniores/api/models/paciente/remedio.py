from extensions import db

class Remedio(db.Model):
    """Medicamento cadastrado para um paciente especifico."""

    __tablename__ = 'tbl_remedio'

    id = db.Column(db.Integer,  primary_key = True)
    nome = db.Column(db.String(60), nullable = False)
    descricao = db.Column(db.String(255), nullable = True)
    dosagem = db.Column(db.String(20), nullable = False)
    frequencia = db.Column(db.String(20), nullable=False, default="diario")
    horarios = db.Column(db.JSON, nullable=False, default=list)
    alertas = db.Column(db.JSON, nullable=False, default=list)
    fabricante = db.Column(db.String(100), nullable=True)
    lote = db.Column(db.String(60), nullable=True)
    quantidade = db.Column(db.Integer, nullable=True)
    alerta_sonoro = db.Column(db.Boolean, nullable=False, default=False)
    som_alerta = db.Column(db.String(120), nullable=True)
    foto_nome = db.Column(db.String(255), nullable=True)
    foto_nome_armazenado = db.Column(db.String(255), nullable=True, unique=True)
    foto_mime = db.Column(db.String(80), nullable=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )

    # Permite navegar de um medicamento para o paciente sem montar consulta manual.
    paciente = db.relationship("Paciente", back_populates="remedios")
    administracoes = db.relationship(
        "AdministracaoMedicamento",
        back_populates="medicamento",
        cascade="all, delete-orphan",
    )

    @property
    def to_dict(self):
        # Formato unico usado nas respostas HTTP de medicamento.
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "nome": self.nome,
            "descricao": self.descricao,
            "dosagem": self.dosagem,
            "frequencia": self.frequencia,
            "horarios": self.horarios or [],
            "alertas": self.alertas or [],
            "fabricante": self.fabricante,
            "lote": self.lote,
            "quantidade": self.quantidade,
            "alerta_sonoro": self.alerta_sonoro,
            "som_alerta": self.som_alerta,
            "foto_nome": self.foto_nome,
        }

    def __str__(self):
        return f"Remedio(nome='{self.nome}', descricao='{self.descricao}', dosagem='{self.dosagem}')"

    def __repr__(self):
        return self.__str__()

    @classmethod
    def buscar_por_id(cls, medicamento_id):
        return db.session.get(cls, medicamento_id)

    @classmethod
    def listar_por_paciente(cls, paciente_id):
        return db.session.scalars(
            db.select(cls).where(cls.paciente_id == paciente_id).order_by(cls.nome)
        ).all()

    @classmethod
    def criar(cls, paciente_id, info):
        medicamento = cls(
            paciente_id=paciente_id, nome=info["nome"],
            descricao=info.get("descricao"), dosagem=info["dosagem"],
            frequencia=info.get("frequencia", "diario"),
            horarios=info.get("horarios", []),
            alertas=info.get("alertas", []),
            fabricante=info.get("fabricante"), lote=info.get("lote"),
            quantidade=info.get("quantidade"),
            alerta_sonoro=info.get("alerta_sonoro", False),
            som_alerta=info.get("som_alerta"),
        )
        return medicamento.salvar()

    def atualizar(self, info, campos_editaveis):
        for campo in campos_editaveis:
            if campo in info:
                setattr(self, campo, info[campo])
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
    
