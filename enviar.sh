
#!/usr/bin/env bash

set -euo pipefail

# 1. Verifica a URL do repositório
if [ -z "${1:-}" ]; then
    echo "❌ Informe a URL do repositório GitHub."
    echo "Exemplo: bash enviar.sh https://github.com/usuario/projeto.git"
    exit 1
fi

REPO_URL="$1"

echo "🚀 Preparando o repositório..."

# 2. Inicializa o Git, se necessário
if [ ! -e ".git" ]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Execute o script na raiz do projeto Git."
        exit 1
    fi

    git init -b main
    echo "✅ Git inicializado."
fi

# 3. Verifica repositórios aninhados sem apagá-los
NESTED_GIT=$(find . -mindepth 2 -name ".git" -print -quit)

if [ -n "$NESTED_GIT" ]; then
    echo "❌ Repositório Git aninhado encontrado:"
    echo "$NESTED_GIT"
    echo "Verifique antes de continuar. Nada foi apagado."
    exit 1
fi

# 4. Configura o repositório remoto
if git remote get-url origin >/dev/null 2>&1; then
    URL_ATUAL=$(git remote get-url origin)

    if [ "$URL_ATUAL" != "$REPO_URL" ]; then
        echo "❌ A origem atual é diferente:"
        echo "$URL_ATUAL"
        echo "Confirme o repositório antes de alterar a origem."
        exit 1
    fi
else
    git remote add origin "$REPO_URL"
fi

# 5. Adiciona alterações respeitando .gitignore
echo "📦 Adicionando alterações..."
git add -A

# 6. Impede o envio acidental de credenciais
while IFS= read -r -d '' ARQUIVO; do
    NOME="${ARQUIVO##*/}"

    if [[ "$NOME" == ".env" ||
          ( "$NOME" == .env.* && "$NOME" != ".env.example" ) ||
          "$NOME" == *.pem ||
          "$NOME" == *.key ||
          "$NOME" == *.p12 ||
          "$NOME" == *.pfx ]]; then
        echo "❌ Arquivo sensível incluído: $ARQUIVO"
        echo "Atualize o .gitignore e retire-o do índice."
        echo "Nenhum commit ou push foi realizado."
        exit 1
    fi
done < <(git diff --cached --name-only -z)

# 7. Mostra o resumo do que será enviado
echo ""
echo "📋 Resumo das alterações:"
git status --short

# 8. Solicita a mensagem personalizada do commit
if ! git diff --cached --quiet; then
    echo ""
    echo "💬 Escreva a mensagem do seu commit:"
    read -r -p "Título: " COMMIT_MSG

    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="Atualização do projeto"
    fi

    echo ""
    read -r -p "Descrição adicional (opcional): " DESCRICAO

    # 9. Cria o commit
    echo "💾 Criando commit..."

    if [ -n "$DESCRICAO" ]; then
        git commit -m "$COMMIT_MSG" -m "$DESCRICAO"
    else
        git commit -m "$COMMIT_MSG"
    fi
else
    echo "ℹ️ Nenhuma alteração nova para commitar."
fi

# 10. Confirma antes de enviar
BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "❌ Não foi possível identificar a branch atual."
    exit 1
fi

echo ""
echo "🌐 Repositório: $REPO_URL"
echo "🌿 Branch: $BRANCH"

read -r -p "Deseja enviar para o GitHub? (s/n): " CONFIRMAR

if [[ "$CONFIRMAR" != "s" && "$CONFIRMAR" != "S" ]]; then
    echo "⏸️ Envio cancelado. O commit local foi preservado."
    exit 0
fi

# 11. Envia sem sobrescrever histórico remoto
echo "📤 Enviando para o GitHub..."

if git push -u origin "$BRANCH"; then
    echo "✅ Projeto atualizado com sucesso!"
else
    echo "❌ O push não foi concluído."
    echo "Verifique se existem commits remotos que precisam ser integrados."
    exit 1
fi
