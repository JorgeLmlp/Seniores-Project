
from extensions import db
from ..user import Usuario



class Cuidador(Usuario):
    """Usuario que presta cuidados e pode estar associado a um paciente."""

    __tablename__ = 'cuidadores'
    id = db.Column(db.Integer, primary_key=True)
    experience = db.Column(db.String(255), nullable=True)
    pacientes = db.relationship("Paciente", back_populates="cuidador")

    responsaveis = db.relationship(
        "Responsavel",
        secondary="cuidador_responsavel",
        back_populates="cuidadores",
    )
    __mapper_args__ = {
        'polymorphic_identity': 'cuidador'
    }

    @property
    def to_dict(self):
        """Inclui IDs e dados completos dos pacientes vinculados ao cuidador."""
        dados = super().to_dict
        pacientes = sorted(self.pacientes, key=lambda paciente: (paciente.name, paciente.id))
        dados["pacientes_ids"] = [paciente.id for paciente in pacientes]
        dados["pacientes"] = [paciente.to_dict for paciente in pacientes]
        return dados

    
