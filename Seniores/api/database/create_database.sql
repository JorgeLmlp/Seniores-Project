CREATE DATABASE IF NOT EXISTS seniores
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Opcional: Cria um usuário exclusivo para a API Flask (Melhor prática de segurança)
CREATE USER IF NOT EXISTS 'flask_user'@'localhost' IDENTIFIED BY 'sua_senha_segura';

-- Opcional: Dá permissões para o usuário gerenciar este banco específico
GRANT ALL PRIVILEGES ON meu_banco_flask.* TO 'flask_user'@'localhost';

-- Aplica as alterações de permissões
FLUSH PRIVILEGES;