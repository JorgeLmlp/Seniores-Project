# 🐳 Docker Setup - Seniores API

Todos os arquivos Docker estão organizados nesta pasta para melhor gerenciamento.

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `Dockerfile` | Imagem multi-stage, otimizada |
| `docker-compose.yml` | Produção (porta 5001) |
| `docker-compose.dev.yml` | Desenvolvimento (porta 5000) |
| `docker-entrypoint.sh` | Script que aguarda MySQL pronto |
| `.env` | Variáveis de ambiente (NÃO COMMITAR) |
| `.env.example` | Template para .env (seguro) |
| `.dockerignore` | Arquivos excluídos do build |

## Rodar

### Opção 1: Comando Direto
```bash
docker compose -f docker/docker-compose.yml up -d
```

### Opção 2: Script (Recomendado)
```bash
./start.sh
```

### Opção 3: Desenvolvimento
```bash
docker compose -f docker/docker-compose.dev.yml up -d
```

## Acessar

- **API**: http://localhost:5001
- **MySQL**: localhost:3306

## Parar

```bash
docker compose -f docker/docker-compose.yml down
```

## Logs

```bash
docker compose -f docker/docker-compose.yml logs -f
```

## Credenciais

Veja `docker/.env` para usuário e senha do MySQL.
