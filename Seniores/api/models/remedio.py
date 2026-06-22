
from cuidador import Usuario
from extensions import db

class Remedio(db.Model):
    
    __tablename__ = 'tbl_remedio'
    def __init__(self, nome, descricao, dosagem):
        super().__init__(nome=nome)
        self.descricao = descricao
        self.dosagem = dosagem

    def __str__(self):
        return f"Remedio(nome='{self.nome}', descricao='{self.descricao}', dosagem='{self.dosagem}')"

    def __repr__(self):
        return self.__str__()
    
    def alterar_dosagem(self, nova_dosagem):
        self.dosagem = nova_dosagem