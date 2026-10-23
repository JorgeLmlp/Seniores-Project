from flask import Flask, g, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text
import os
from dotenv import load_dotenv

# A instancia e criada sem app para poder ser importada por models e services.
db = SQLAlchemy()

app = Flask(__name__)
# Permite que a versao Flutter Web acesse a API durante o desenvolvimento.
# Aplicativos Flutter nativos (Android/iOS/Windows) nao dependem de CORS.
CORS(app, resources={r"/*": {"origins": "*"}})
# Carrega as variáveis antes de configurar o Flask.
load_dotenv()
app.config["SECRET_KEY"] = os.getenv(
    "SENIORES_SECRET_KEY", "seniores-local-development-secret-change-me"
)
app.config["SMTP_HOST"] = os.getenv("SMTP_HOST")
app.config["SMTP_PORT"] = os.getenv("SMTP_PORT", "587")
app.config["SMTP_USER"] = os.getenv("SMTP_USER")
app.config["SMTP_PASSWORD"] = os.getenv("SMTP_PASSWORD")
app.config["PASSWORD_RESET_FROM"] = os.getenv("PASSWORD_RESET_FROM")
app.config["REPORT_FROM"] = os.getenv("REPORT_FROM")
app.config["PASSWORD_RESET_URL"] = os.getenv(
    "PASSWORD_RESET_URL", "seniores://redefinir-senha?token="
)
pasta = os.path.abspath(os.path.join(os.path.dirname(__file__), "database"))

# Usa o banco informado no ambiente; sem ele, cria/usa SQLite local.
database_url = os.getenv("DATABASE_URL", f"sqlite:///{os.path.join(pasta, 'database.db')}")
app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)


ROTAS_PUBLICAS = {
    ("POST", "/users/login/"),
    ("POST", "/users/password-reset/request"),
    ("POST", "/users/password-reset/confirm"),
    ("POST", "/users/"),
    ("POST", "/cuidador"),
    ("POST", "/paciente"),
    ("POST", "/responsavel"),
}


def _rota_publica():
    return request.method == "OPTIONS" or (request.method, request.path) in ROTAS_PUBLICAS


@app.before_request
def autenticar_requisicao():
    if _rota_publica():
        return None
    if request.endpoint is None:
        return None
    autorizacao = request.headers.get("Authorization", "")
    if not autorizacao.startswith("Bearer "):
        return jsonify({"erro": "Autenticacao obrigatoria"}), 401
    token = autorizacao.removeprefix("Bearer ").strip()
    if not token:
        return jsonify({"erro": "Sessao invalida ou expirada"}), 401
    from services.auth_service import ler_token

    usuario = ler_token(token)
    if usuario is None:
        return jsonify({"erro": "Sessao invalida ou expirada"}), 401
    g.usuario = usuario
    g.usuario_id = usuario.id
    g.tipo_usuario = usuario.tipo
    from services.authorization_service import autorizar_requisicao

    autorizacao = autorizar_requisicao()
    if autorizacao is not None:
        mensagem, status = autorizacao
        return jsonify(mensagem), status
    return None

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

    colunas_perfil = {
        "idade": "INTEGER",
        "tipo_sanguineo": "VARCHAR(5)",
        "preferencias": "VARCHAR(500)",
        "senha_reset_nonce": "VARCHAR(128)",
    }
    for tabela in ("pacientes", "cuidadores", "responsaveis"):
        if tabela not in inspect(db.engine).get_table_names():
            continue
        existentes = {
            coluna["name"] for coluna in inspect(db.engine).get_columns(tabela)
        }
        for nome, tipo in colunas_perfil.items():
            if nome not in existentes:
                with db.engine.begin() as conexao:
                    conexao.execute(
                        text(f"ALTER TABLE {tabela} ADD COLUMN {nome} {tipo} NULL")
                    )

    if "tbl_remedio" in inspect(db.engine).get_table_names():
        colunas_remedios = {
            "frequencia": "VARCHAR(20) DEFAULT 'diario'",
            "horarios": "JSON DEFAULT '[]'",
            "alertas": "JSON DEFAULT '[]'",
            "alerta_sonoro": "BOOLEAN DEFAULT 0",
            "som_alerta": "VARCHAR(120)",
            "foto_nome": "VARCHAR(255)",
            "foto_nome_armazenado": "VARCHAR(255)",
            "foto_mime": "VARCHAR(80)",
        }
        existentes = {
            coluna["name"]
            for coluna in inspect(db.engine).get_columns("tbl_remedio")
        }
        for nome, tipo in colunas_remedios.items():
            if nome not in existentes:
                with db.engine.begin() as conexao:
                    conexao.execute(
                        text(f"ALTER TABLE tbl_remedio ADD COLUMN {nome} {tipo}")
                    )


with app.app_context():
    # Importar os models faz o SQLAlchemy conhecer todas as tabelas antes do create_all.
    import models
    # Cria apenas tabelas inexistentes; alteracoes em tabelas ja criadas exigem migracao.
    db.create_all()
    migrar_schema_existente()





