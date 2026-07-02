from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os

db = SQLAlchemy()   

def create_app():
    app = Flask(__name__)

    pasta = os.path.abspath(os.path.join(os.path.dirname(__file__), "database"))

    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///" + os.path.join(pasta, "seniores.db")
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    db.init_app(app)

    with app.app_context():
        import models
        db.create_all()

    return app



