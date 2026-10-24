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
    frequencia = db.Column(db.String(30), nullable=False)
    horarios = db.Column(db.JSON, nullable=True)
    alertas = db.Column(db.JSON, nullable=True)
    alerta_sonoro = db.Column(db.Boolean, nullable=False, default=False)
    som_alerta = db.Column(db.String(120), nullable=True)
    paciente_id = db.Column(
        db.Integer,
        db.ForeignKey("pacientes.id"),
        nullable=False,
        index=True,
    )

    # Permite navegar de um medicamento para o paciente sem montar consulta manual.
    paciente = db.relationship("Paciente", back_populates="remedios")

    @property
    def foto_url(self):
        # Uses the existing flexible records table: no DDL on shared Aiven.
        from models.paciente.registro_app import RegistroApp
        existe = db.session.scalar(db.select(RegistroApp.id).where(
            RegistroApp.paciente_id == self.paciente_id,
            RegistroApp.recurso == f'medfoto:{self.id}',
        ).limit(1))
        return f'/medicamentos/{self.id}/foto' if existe is not None else None

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
            "frequencia": self.frequencia,
            "horarios": self.horarios or [],
            "alertas": self.alertas or [],
            "alerta_sonoro": self.alerta_sonoro,
            "som_alerta": self.som_alerta,
            "foto_url": self.foto_url,
        }

    def __str__(self):
        return f"Remedio(nome='{self.nome}', descricao='{self.descricao}', dosagem='{self.dosagem}')"

    def __repr__(self):
        return self.__str__()

    @classmethod
    def criar(cls, paciente_id, info):
        medicamento = cls(
            paciente_id=paciente_id, nome=info["nome"],
            descricao=info.get("descricao"), dosagem=info["dosagem"],
            fabricante=info.get("fabricante"), lote=info.get("lote"),
            quantidade=info.get("quantidade"),
            frequencia=info.get("frequencia"), horarios=info.get("horarios") or [],
            alertas=info.get("alertas") or [],
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
