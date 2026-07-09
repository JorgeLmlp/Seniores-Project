CREATE DATABASE IF NOT EXISTS seniores
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'flask_user'@'localhost' IDENTIFIED BY 'sua_senha_segura';

GRANT ALL PRIVILEGES ON meu_banco_flask.* TO 'flask_user'@'localhost';

FLUSH PRIVILEGES;