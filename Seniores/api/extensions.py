from flask import Flask
from .env import user, password
from flask_sqlalchemy import SQLAlchemy
import os

db = SQLAlchemy()   

app = Flask(__name__)

pasta = os.path.abspath(os.path.join(os.path.dirname(__file__), "database"))

app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://{user}@localhost:3306/db_seniores'
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = True

db.init_app(app)

from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)
    
with app.app_context():
    import models
    db.create_all()





