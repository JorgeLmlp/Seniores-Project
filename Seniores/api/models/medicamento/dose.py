from extensions import db

class Dose(db.Model):
    __tablename__ = 'status_doses'
    medicamento_id = db.Column(db.Integer, db.ForeignKey('tbl_remedio.id', ondelete='CASCADE'), primary_key=True)
    data = db.Column(db.String(10), primary_key=True)
    horario = db.Column(db.String(5), primary_key=True)
    concluida = db.Column(db.Boolean, nullable=False, default=False)
