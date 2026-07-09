from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os

db = SQLAlchemy()   

app = Flask(__name__)

pasta = os.path.abspath(os.path.join(os.path.dirname(__file__), "database"))

app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://usuario:senha@localhost:3306/nome_do_banco'
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)

from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)
    
with app.app_context():
    import models
    db.create_all()





