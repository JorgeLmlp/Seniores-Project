from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text
from sqlalchemy.engine import make_url
import os
from dotenv import load_dotenv

# A instancia e criada sem app para poder ser importada por models e services.
db = SQLAlchemy()

app = Flask(__name__)
# Permite que a versao Flutter Web acesse a API durante o desenvolvimento.
# Aplicativos Flutter nativos (Android/iOS/Windows) nao dependem de CORS.
CORS(app, resources={r"/*": {"origins": "*"}})
# Carrega DATABASE_URL e DEBUG antes de configurar o Flask.
load_dotenv()
database_url = os.getenv("DATABASE_URL")
if not database_url:
    raise RuntimeError("DATABASE_URL deve apontar para um banco MySQL.")


def criar_banco_mysql_se_necessario(url_banco):
    """Cria o schema MySQL configurado antes de o SQLAlchemy criar tabelas.

    Exemplo de DATABASE_URL:
    ``mysql+pymysql://usuario:senha@localhost:3306/seniores?charset=utf8mb4``.
    O usuario precisa ter permissao de criar bancos no servidor MySQL.
    """
    url = make_url(url_banco)
    if not url.drivername.startswith("mysql") or not url.database:
        raise RuntimeError("DATABASE_URL deve ser uma URL MySQL com o nome do banco.")

    # O identificador nao e parametro SQL; escapar a crase impede injecao no DDL.
    nome_banco = url.database.replace("`", "``")
    opcoes = dict(url.query)
    charset = opcoes.pop("charset", "utf8mb4")

    try:
        import pymysql
        conexao = pymysql.connect(
            host=url.host or "localhost", port=url.port or 3306,
            user=url.username, password=url.password, charset=charset,
            **opcoes,
        )
        try:
            with conexao.cursor() as cursor:
                cursor.execute(
                    f"CREATE DATABASE IF NOT EXISTS `{nome_banco}` "
                    f"CHARACTER SET {charset}"
                )
            conexao.commit()
        finally:
            conexao.close()
    except ImportError as erro:
        raise RuntimeError("Instale as dependencias com `pip install -r requirements.txt`.") from erro


criar_banco_mysql_se_necessario(database_url)

app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)

# Blueprints concentram as rotas por assunto e sao registrados na inicializacao.
from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)


def migrar_schema_existente():
    """Acrescenta colunas criadas depois que o banco ja existia.

    `create_all` nao altera tabelas existentes. Esta migracao e aditiva: nao
    remove dados nem modifica valores ja armazenados.
    """
    colunas_pacientes = {
        coluna["name"] for coluna in inspect(db.engine).get_columns("pacientes")
    }
    colunas_novas = {
        "cuidador_id": "INTEGER",
        "responsavel_id": "INTEGER",
    }
    with db.engine.begin() as conexao:
        for nome, tipo in colunas_novas.items():
            if nome not in colunas_pacientes:
                conexao.execute(
                    text(f"ALTER TABLE pacientes ADD COLUMN {nome} {tipo} NULL")
                )

        # Mantem bancos ja criados compativeis com o armazenamento de fotos.
        colunas_lesoes = {
            coluna["name"] for coluna in inspect(db.engine).get_columns("lesoes")
        }
        for nome, tipo in {"foto": "BLOB", "foto_mime": "VARCHAR(50)"}.items():
            if nome not in colunas_lesoes:
                conexao.execute(text(f"ALTER TABLE lesoes ADD COLUMN {nome} {tipo} NULL"))


with app.app_context():
    # Importar os models faz o SQLAlchemy conhecer todas as tabelas antes do create_all.
    import models
    # Cria apenas tabelas inexistentes; alteracoes em tabelas ja criadas exigem migracao.
    db.create_all()
    migrar_schema_existente()


