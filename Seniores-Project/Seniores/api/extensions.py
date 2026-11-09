from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text
from sqlalchemy.engine import make_url
import os
import secrets
from dotenv import load_dotenv

# A instancia e criada sem app para poder ser importada por models e services.
db = SQLAlchemy()

app = Flask(__name__)
# Permite que a versao Flutter Web acesse a API durante o desenvolvimento.
# Aplicativos Flutter nativos (Android/iOS/Windows) nao dependem de CORS.
CORS(app,resources={r"/*": {"origins": "*"}})
# Carrega DATABASE_URL e DEBUG antes de configurar o Flask.
na_vercel = os.getenv('VERCEL') == '1'
if not na_vercel:
    load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))
if na_vercel:
    if not os.getenv('DATABASE_URL', '').startswith('mysql+pymysql://'):
        raise RuntimeError('Na Vercel, configure DATABASE_URL com um MySQL externo (mysql+pymysql://).')
    if not os.getenv('SECRET_KEY'):
        raise RuntimeError('Na Vercel, configure uma SECRET_KEY fixa para validar as sessoes.')
    if os.getenv('API_TESTING') == '1':
        raise RuntimeError('API_TESTING nao pode estar habilitado na Vercel.')
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY') or secrets.token_hex(32)
database_url = os.getenv("DATABASE_URL", "sqlite:///seniores-local.db")


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
            connect_timeout=5,
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


if database_url.startswith("mysql"):
    if os.getenv('AUTO_CREATE_DATABASE', '0' if na_vercel else '1') == '1':
        criar_banco_mysql_se_necessario(database_url)
elif not database_url.startswith("sqlite"):
    raise RuntimeError("DATABASE_URL deve apontar para MySQL ou SQLite.")

app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
if database_url.startswith('mysql'):
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_pre_ping': True, 'pool_recycle': 280,
        'pool_size': 2, 'max_overflow': 0,
    }

db.init_app(app)

# Blueprints concentram as rotas por assunto e sao registrados na inicializacao.
from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)

import access


def migrar_sinais_vitais(conexao):
    """Preserva medidas antigas sem atribuí-las a um paciente arbitrário."""
    inspector = inspect(conexao)
    colunas = {coluna['name'] for coluna in inspector.get_columns('sinais_vitais')}
    if 'paciente_id' not in colunas:
        conexao.execute(text('ALTER TABLE sinais_vitais ADD COLUMN paciente_id INTEGER NULL'))
    indices = {indice['name'] for indice in inspect(conexao).get_indexes('sinais_vitais')}
    if 'ix_sinais_vitais_paciente_id' not in indices:
        conexao.execute(text('CREATE INDEX ix_sinais_vitais_paciente_id ON sinais_vitais (paciente_id)'))


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
        "preferiencias": "TEXT",
        "idade": "INTEGER",
        "tipo_sanguineo": "VARCHAR(5)",
        "preferencias": "JSON",
    }
    with db.engine.begin() as conexao:
        migrar_sinais_vitais(conexao)
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

        tabelas_colunas = {
            "tbl_remedio": {
                "frequencia": "VARCHAR(30)", "horarios": "JSON", "alertas": "JSON",
                "alerta_sonoro": "BOOLEAN NOT NULL DEFAULT 0", "som_alerta": "VARCHAR(120)",
            },
            "diarios_saude": {
                "humor_nivel": "INTEGER", "dor_nivel": "INTEGER",
                "apetite_nivel": "INTEGER", "mobilidade_nivel": "INTEGER",
                "incidentes": "JSON", "duvidas": "TEXT",
                "sono": "VARCHAR(8)", "sono_nivel": "INTEGER",
            },
        }
        for tabela, definicoes in tabelas_colunas.items():
            existentes = {
                coluna["name"] for coluna in inspect(db.engine).get_columns(tabela)
            }
            for nome, tipo in definicoes.items():
                if nome not in existentes:
                    conexao.execute(
                        text(f"ALTER TABLE {tabela} ADD COLUMN {nome} {tipo} NULL")
                    )


def inicializar_banco():
    """Prepara as tabelas em uma etapa explicita antes do deploy."""
    with app.app_context():
        db.create_all()
        migrar_schema_existente()


@app.cli.command('init-db')
def init_db_command():
    inicializar_banco()
    print('Tabelas e migracoes preparadas.')


with app.app_context():
    # Importar os models faz o SQLAlchemy conhecer todas as tabelas antes do create_all.
    import models
    # Cria apenas tabelas inexistentes; alteracoes em tabelas ja criadas exigem migracao.
    if os.getenv('AUTO_INIT_DB', '0' if na_vercel else '1') == '1':
        inicializar_banco()
