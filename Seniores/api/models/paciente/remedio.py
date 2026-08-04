from extensions import db

class Remedio(db.Model):
    """Medicamento cadastrado para um paciente especifico."""

    __tablename__ = 'tbl_remedio'

    id = db.Column(db.Integer,  primary_key = True)
    nome = db.Column(db.String(60), nullable = False)
    descricao = db.Column(db.String(255), nullable = True)
    dosagem = db.Column(db.String(20), nullable = False)
    fabricante = db.Column(db.String(100), nullable=True)
    lote = db.Column(db.String(60), nullable=True)
    quantidade = db.Column(db.Integer, nullable=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )

    # Permite navegar de um medicamento para o paciente sem montar consulta manual.
    paciente = db.relationship("Paciente", back_populates="remedios")

    @property
    def to_dict(self):
        # Formato unico usado nas respostas HTTP de medicamento.
        return {
            "id": self.id,
            "paciente_id": self.paciente_id,
            "nome": self.nome,
            "descricao": self.descricao,
            "dosagem": self.dosagem,
            "fabricante": self.fabricante,
            "lote": self.lote,
            "quantidade": self.quantidade,
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
            fabricante=info.get("fabricante"), lote=info.get("lote"),
            quantidade=info.get("quantidade"),
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
    
