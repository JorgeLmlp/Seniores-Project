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
    
    
