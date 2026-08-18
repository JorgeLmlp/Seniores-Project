#!/bin/bash

# 1. Verifica se a URL do repositório foi passada
if [ -z "$1" ]; then
    echo "❌ Erro: Você precisa passar a URL do repositório GitHub."
    echo "👉 Exemplo: ./enviar.sh https://github.com/seu-usuario/seu-repositorio.git"
    exit 1
fi

REPO_URL=$1

echo "🚀 Iniciando a preparação do repositório..."

# 2. Inicializa o Git na pasta raiz
if [ ! -d ".git" ]; then
    git init -b main
    echo "✅ Repositório Git inicializado na raiz."
else
    echo "🔄 Git já inicializado na raiz."
fi

# [NOVO] 3. Garante que o Git limpe o cache para respeitar os .gitignore locais
# Se algum arquivo build/ ou gerado tentou ser rastreado antes, isso resolve.
echo "🧹 Atualizando índice de arquivos para respeitar os .gitignore locais..."
git rm -r --cached . 2>/dev/null

# 4. REMOVE .git de dentro das subpastas (Evita o problema de submódulos)
echo "🔍 Verificando e limpando possíveis sub-repositórios..."
find . -mindepth 2 -name ".git" -type d -exec rm -rf {} + 2>/dev/null

# 5. Vincula ao repositório remoto
git remote remove origin 2>/dev/null
git remote add origin "$REPO_URL"

# 6. Adiciona os arquivos (respeitando rigorosamente os .gitignore), commita e envia
echo "📦 Adicionando arquivos ao Git..."
git add .

echo "💾 Criando o commit..."
git commit -m "Upload de projetos Flutter respeitando .gitignore locais"

echo "📤 Enviando para o GitHub..."
git push -u origin main --force

echo "🎉 Tudo pronto! Seus projetos estão no GitHub e suas pastas build/ foram ignoradas!"