
from .cuidador import Usuario
from extensions import db

class Remedio(db.Model):
    __allow_unmapped__ = True
    __tablename__ = 'tbl_remedio'
            
    id = db.Column(db.Integer,  primary_key = True)
    nome = db.Column(db.String(60), nullable = False)
    descricao = db.Column(db.String(255), nullable = False)
    dosagem = db.Column(db.String(20), nullable = False)

    def __str__(self):
        return f"Remedio(nome='{self.nome}', descricao='{self.descricao}', dosagem='{self.dosagem}')"

    def __repr__(self):
        return self.__str__()
    
    