from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv

db = SQLAlchemy()   

app = Flask(__name__)
load_dotenv()
pasta = os.path.abspath(os.path.join(os.path.dirname(__file__), "database"))

database_url = os.getenv("DATABASE_URL", f"sqlite:///{os.path.join(pasta, 'database.db')}")
app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)

from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)
    
with app.app_context():
    import models
    db.create_all()





