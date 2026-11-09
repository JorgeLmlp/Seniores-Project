from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text
from sqlalchemy.engine import make_url
import os
import secrets
import ssl
from dotenv import load_dotenv

# A instancia e criada sem app para poder ser importada por models e services.
db = SQLAlchemy()

app = Flask(__name__)
# Permite que a versao Flutter Web acesse a API durante o desenvolvimento.
# Aplicativos Flutter nativos (Android/iOS/Windows) nao dependem de CORS.
CORS(app,resources={r"/*": {"origins": "*"}})
# Carrega DATABASE_URL e DEBUG antes de configurar o Flask.
load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY') or secrets.token_hex(32)
database_url = os.getenv('DATABASE_URL')
if not database_url:
    raise RuntimeError('Configure DATABASE_URL no .env (nunca no Flutter).')
# URI copiada do painel Aiven costuma usar mysql://.
if database_url.startswith('mysql://'):
    database_url = 'mysql+pymysql://' + database_url[len('mysql://'):]
# ssl-mode=REQUIRED pertence ao cliente MySQL CLI; PyMySQL utiliza SSLContext.
url_temporaria = make_url(database_url)
if 'ssl-mode' in url_temporaria.query:
    modo = url_temporaria.query['ssl-mode']
    if str(modo).upper() != 'REQUIRED':
        raise RuntimeError('A URI aceita apenas ssl-mode=REQUIRED; configure DB_SSL_CA.')
    url_temporaria = url_temporaria.difference_update_query(['ssl-mode'])
    database_url = url_temporaria.render_as_string(hide_password=False)

jwt_secret_key = os.getenv("JWT_SECRET_KEY")
if not jwt_secret_key or len(jwt_secret_key) < 32:
    raise RuntimeError(
        "JWT_SECRET_KEY deve estar configurada com pelo menos 32 caracteres aleatorios."
    )

try:
    jwt_access_token_minutes = int(os.getenv("JWT_ACCESS_TOKEN_MINUTES", "60"))
except ValueError as erro:
    raise RuntimeError("JWT_ACCESS_TOKEN_MINUTES deve ser um numero inteiro.") from erro
if not 1 <= jwt_access_token_minutes <= 1440:
    raise RuntimeError("JWT_ACCESS_TOKEN_MINUTES deve estar entre 1 e 1440.")


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


# MySQL remoto: nao executar CREATE DATABASE nem migracoes automaticamente.
# TLS com verificacao por CA fornecida pelo provedor, sem desabilitar a verificacao.
url_config = make_url(database_url)
remoto = False
if url_config.drivername.startswith('mysql'):
    remoto = (url_config.host or '').lower() not in {'localhost', '127.0.0.1', '::1'}
    ca = os.getenv('DB_SSL_CA', '').strip()
    if remoto:
        if not ca or not os.path.isfile(ca):
            raise RuntimeError('MySQL remoto requer DB_SSL_CA com caminho do certificado CA valido.')
        contexto_ssl = ssl.create_default_context(cafile=ca)
        contexto_ssl.check_hostname = True
        contexto_ssl.verify_mode = ssl.CERT_REQUIRED
        app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
            'connect_args': {'ssl': contexto_ssl, 'connect_timeout': 10}
        }
    else:
        if os.getenv('DB_AUTO_SCHEMA', '1') == '1':
            criar_banco_mysql_se_necessario(database_url)
elif not database_url.startswith('sqlite'):
    raise RuntimeError('DATABASE_URL deve apontar para MySQL ou SQLite de testes.')

# Em hospedagem compartilhada nao alteramos schema na inicializacao.
# Migracoes devem ser feitas em procedimento separado, com backup.
AUTO_SCHEMA = os.getenv('DB_AUTO_SCHEMA', '0' if remoto else '1') == '1'
if remoto and AUTO_SCHEMA:
    raise RuntimeError('Nao habilite DB_AUTO_SCHEMA em banco remoto compartilhado.')

app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["JWT_SECRET_KEY"] = jwt_secret_key
app.config["JWT_ACCESS_TOKEN_MINUTES"] = jwt_access_token_minutes

db.init_app(app)

# Blueprints concentram as rotas por assunto e sao registrados na inicializacao.
from routes import blueprints

for bp in blueprints:
    app.register_blueprint(bp)


def migrar_sinais_vitais(conexao):
    """Preserva medidas antigas sem atribuí-las a um paciente arbitrário."""
    inspector = inspect(conexao)
    colunas = {coluna['name'] for coluna in inspector.get_columns('sinais_vitais')}
    if 'paciente_id' not in colunas:
        conexao.execute(text('ALTER TABLE sinais_vitais ADD COLUMN paciente_id INTEGER NULL'))
    indices = {indice['name'] for indice in inspect(conexao).get_indexes('sinais_vitais')}
    if 'ix_sinais_vitais_paciente_id' not in indices:
        conexao.execute(text('CREATE INDEX ix_sinais_vitais_paciente_id ON sinais_vitais (paciente_id)'))

# Login e cadastro sao publicos; todo o restante da API exige JWT valido.
from security.jwt_auth import registrar_protecao_jwt

registrar_protecao_jwt(app)



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


with app.app_context():
    # Importar os models faz o SQLAlchemy conhecer todas as tabelas antes do create_all.
    import models
    # Cria apenas tabelas inexistentes; alteracoes em tabelas ja criadas exigem migracao.
    if AUTO_SCHEMA:
        db.create_all()
        migrar_schema_existente()
