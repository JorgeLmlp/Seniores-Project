from flask import Flask
from extensions import db, app
from routes import *

def create_app():

    db.init_app(app)  

    with app.app_context():
        from models.cuidador import User, Cuidador  
        db.create_all()
    
    return app

if __name__ == '__main__':
    app.run(debug=True)