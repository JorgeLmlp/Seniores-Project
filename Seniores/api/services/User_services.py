from flask import jsonify, request
from extensions import db
from werkzeug.security import generate_password_hash
from models.cuidador import Cuidador


#classe que contem todos os metodos relacionados a usuarios, como registro, login, etc.
class UserService:
    def registrarCuidador(self, info):
        nome = info.get('nome')
        email = info.get('email')
        senha = info.get('senha')
        telefone = info.get('telefone')
        endereco = info.get('endereco')
        cpf = info.get('cpf')


        #verifica se o usuario existe no banco de dados
        if db.session.query(Cuidador).filter((Cuidador.email == email) | (Cuidador.cpf == cpf)).first():
            return 409  
        senha_hash = generate_password_hash(senha)
        cuidador = Cuidador(nome=nome, email=email, senha=senha_hash, telefone=telefone, endereco=endereco, cpf=cpf)
        try:
            db.session.add(cuidador)
            db.session.commit()
            return cuidador  # Retorna o objeto para o controller se for criado com sucesso
        except Exception as e:
            db.session.rollback()  # Desfaz qualquer mudança parcial
            raise e
