#!/bin/bash

# 1. Verifica se a URL do repositório foi passada
if [ -z "$1" ]; then
    echo "❌ Erro: Você precisa passar a URL do repositório GitHub."
    echo "👉 Exemplo: ./enviar.sh https://github.com/seu-usuario/seu-repositorio.git \"Sua mensagem de commit opcional\""
    exit 1
fi

REPO_URL=$1

# 2. Define a mensagem do commit: usa o segundo argumento ($2) se fornecido, senão usa o padrão
COMMIT_MSG="${2:-Upload de projetos Flutter respeitando .gitignore locais}"

echo "🚀 Iniciando a preparação do repositório..."

# 3. Inicializa o Git na pasta raiz
if [ ! -d ".git" ]; then
    git init -b main
    echo "✅ Repositório Git inicializado na raiz."
else
    echo "🔄 Git já inicializado na raiz."
fi

# [NOVO] 4. Garante que o Git limpe o cache para respeitar os .gitignore locais
echo "🧹 Atualizando índice de arquivos para respeitar os .gitignore locais..."
git rm -r --cached . 2>/dev/null

# 5. REMOVE .git de dentro das subpastas (Evita o problema de submódulos)
echo "🔍 Verificando e limpando possíveis sub-repositórios..."
find . -mindepth 2 -name ".git" -type d -exec rm -rf {} + 2>/dev/null

# 6. Vincula ao repositório remoto
git remote remove origin 2>/dev/null
git remote add origin "$REPO_URL"

# 7. Adiciona os arquivos (respeitando rigorosamente os .gitignore), commita e envia
echo "📦 Adicionando arquivos ao Git..."
git add .

echo "💾 Criando o commit..."
git commit -m "$COMMIT_MSG"

echo "📤 Enviando para o GitHub..."
git push -u origin main --force

echo "🎉 Tudo pronto! Seus projetos estão no GitHub e suas pastas build/ foram ignoradas!"