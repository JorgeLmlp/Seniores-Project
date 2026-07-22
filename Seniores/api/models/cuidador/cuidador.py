
from extensions import db
from ..user import Usuario



class Cuidador(Usuario):
    """Usuario que presta cuidados e pode estar associado a um paciente."""

    __tablename__ = 'cuidadores'
    __allow_unmapped__ = True
    id = db.Column(db.Integer, primary_key=True)
    experience = db.Column(db.String(255), nullable=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'))
    __mapper_args__ = {
        'polymorphic_identity': 'cuidador'
    }

    
