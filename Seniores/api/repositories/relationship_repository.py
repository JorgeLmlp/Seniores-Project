from extensions import db
from flask import jsonify



def pesquisarCpfParaRelacionamento(tipo, cpf):
    query = db.select(tipo).where(tipo.cpf == cpf)
    usuario = db.session.scalars(query).first()
    
    if usuario:
        return usuario.id
    else:
        #cpf nao cadastrado
        return 404
    
    