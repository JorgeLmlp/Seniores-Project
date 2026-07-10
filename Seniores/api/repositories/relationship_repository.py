from extensions import db
from flask import jsonify



def pesquisarCpfParaRelacionamento(tipo, cpf):
    query = db.select(tipo).where(tipo.cpf == cpf)
    usuario = db.session.scalars(query).first()
    
    if usuario:
        return usuario.id
    
    #cpf nao cadastrado
    return jsonify({"erro": "CPF não cadastrado"}), 404    
    