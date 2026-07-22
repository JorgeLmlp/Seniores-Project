-- Cria somente o banco usado pela API.
-- As tabelas sao criadas pelos models SQLAlchemy em extensions.py, via db.create_all().
-- Execute uma vez antes de iniciar a aplicacao em um servidor MySQL novo.

CREATE DATABASE IF NOT EXISTS db_seniores
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
