"""Diagnóstico somente de leitura da conexão com MySQL remoto.

Uso, a partir da pasta api:
    python verificar_aiven.py

IMPORTANTE: não cria banco, não atualiza tabelas e não altera registros.
Exige DB_AUTO_SCHEMA=0 no .env. Mantém senhas e chaves fora do log.
"""

from __future__ import annotations

import os


def main() -> int:
    # Esta verificação deve ser segura inclusive quando executada por engano
    # contra um banco compartilhado. O .env deve desabilitar qualquer DDL.
    if os.getenv("DB_AUTO_SCHEMA", "0") == "1":
        print("ERRO: defina DB_AUTO_SCHEMA=0 antes do diagnóstico.")
        return 2

    try:
        from sqlalchemy import inspect, text
        from extensions import AUTO_SCHEMA, app, db

        if AUTO_SCHEMA:
            print("ERRO: migrações automáticas estão habilitadas; diagnóstico cancelado.")
            return 2

        with app.app_context():
            url = db.engine.url
            if not url.drivername.startswith("mysql"):
                print("ERRO: DATABASE_URL não aponta para MySQL.")
                return 2
            if (url.host or "").lower() in {"localhost", "127.0.0.1", "::1"}:
                print("AVISO: sua DATABASE_URL aponta para um MySQL local, não para a Aiven.")

            print(f"Servidor: {url.host}:{url.port or 3306}")
            print(f"Banco configurado: {url.database}")

            # Ao contrário de db.create_all(), estas operações são SELECTs.
            with db.engine.connect() as connection:
                connection.execute(text("SELECT 1")).scalar_one()
                banco_atual = connection.execute(text("SELECT DATABASE()")).scalar_one()
                existentes = set(inspect(connection).get_table_names())

            esperadas = set(db.metadata.tables)
            faltantes = sorted(esperadas - existentes)
            print("CONEXÃO MYSQL: OK (consulta SELECT 1 executada)")
            print(f"Banco selecionado: {banco_atual}")
            print(f"Tabelas encontradas: {len(existentes)}")
            print(f"Tabelas esperadas pelo código: {len(esperadas)}")
            if faltantes:
                print("ATENÇÃO: as seguintes tabelas ainda não estão disponíveis:")
                for tabela in faltantes:
                    print(f"  - {tabela}")
                print("A equipe deve validar o esquema em um ambiente de teste antes de migrar.")
                return 1
            print("ESQUEMA: todas as tabelas do modelo estão presentes.")
            print("Este diagnóstico não verifica colunas, dados, login nem permissões de usuário.")
            return 0
    except Exception as erro:
        # Não imprimir a exceção inteira: URLs ou parâmetros podem conter segredos.
        print(f"FALHA NO DIAGNÓSTICO: {type(erro).__name__}")
        print("Confira o .env, a CA da Aiven, a rede e as permissões de leitura.")
        return 1


if __name__ == "__main__":
    # Configurar o .env de maneira explícita antes de carregar extensions.
    from dotenv import load_dotenv
    from pathlib import Path

    load_dotenv(Path(__file__).resolve().parent / ".env")
    raise SystemExit(main())
