from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv

# A instancia e criada sem app para poder ser importada por models e services.
db = SQLAlchemy()

app = Flask(__name__)
# Carrega DATABASE_URL e DEBUG antes de configurar o Flask.
load_dotenv()
pasta = os.path.abspath(os.path.join(os.path.dirname(__file__), "database"))

# Usa o banco informado no ambiente; sem ele, cria/usa SQLite local.
database_url = os.getenv("DATABASE_URL", f"sqlite:///{os.path.join(pasta, 'database.db')}")
app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)

# Blueprints concentram as rotas por assunto e sao registrados na inicializacao.
from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)
    
with app.app_context():
    # Importar os models faz o SQLAlchemy conhecer todas as tabelas antes do create_all.
    import models
    # Cria apenas tabelas inexistentes; alteracoes em tabelas ja criadas exigem migracao.
    db.create_all()





