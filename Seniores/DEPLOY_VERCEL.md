# Deploy da API na Vercel

O projeto Vercel deve usar **Root Directory: `Seniores/api`** e **Framework Preset: Flask**.
O arquivo `app.py` exporta a aplicação; não configure Gunicorn, Start Command,
Build Command nem Output Directory. O frontend Flutter continua separado.

## 1. Banco e variáveis

O MySQL já está hospedado no **Aiven** e continuará lá. Apenas a API será
hospedada na Vercel: Flutter → API Flask na Vercel → MySQL no Aiven.
Use o mesmo banco que contém os dados atuais; não é necessário criar outro
banco nem exportar/importar os dados para mudar a hospedagem da API.

Em Settings > Environment Variables, configure:

| Variável | Valor |
| --- | --- |
| `DATABASE_URL` | `mysql+pymysql://USUARIO:SENHA@HOST_AIVEN:PORTA/BANCO_ATUAL?charset=utf8mb4&ssl_ca=certs/aiven-ca.pem&ssl_verify_cert=true&ssl_verify_identity=true` |
| `SECRET_KEY` | Chave aleatória fixa, igual entre instâncias |
| `JWT_SECRET_KEY` | Segunda chave aleatória fixa, com pelo menos 32 caracteres |
| `DB_SSL_CA` | `certs/aiven-ca.pem` |
| `DB_AUTO_SCHEMA` | `0` |
| `DEBUG` | `0` |
| `AUTO_CREATE_DATABASE` | `0` |
| `AUTO_INIT_DB` | `0` |

No Aiven Console, abra o serviço MySQL e consulte **Connection information**.
Use o host, a porta, o usuário e o nome do banco atual exatamente como
configurados (não presuma porta 3306 nem troque o nome por `defaultdb`).
Codifique caracteres especiais do usuário/senha na URL. Se copiar a URI do
Aiven, adapte o prefixo para `mysql+pymysql://` e use os parâmetros acima;
`ssl-mode=REQUIRED` não é um parâmetro de conexão do PyMySQL.

Baixe o certificado CA do serviço Aiven e salve em `api/certs/aiven-ca.pem`.
Inclua esse certificado público no deploy, mantendo o caminho relativo à
pasta `api`. A URL acima ativa TLS com verificação do certificado e do hostname.
Não inclua chaves privadas. Verifique também se as regras de rede do serviço
Aiven permitem conexões da aplicação na Vercel. Não habilite `API_TESTING` na Vercel. Para envio de
relatórios por e-mail, configure também as variáveis `SMTP_*` do README da API.
Use um banco separado para Preview se ativar esse ambiente.

Gere a chave localmente com `python -c "import secrets; print(secrets.token_hex(32))"`.
Não inclua credenciais no Git.

## 2. Preparar tabelas antes de publicar

O banco já existe no Aiven. Se as tabelas estiverem atualizadas, pule esta
etapa. Se houver mudanças pendentes no schema, execute no PowerShell com
acesso ao MySQL do Aiven e com o certificado CA salvo conforme indicado:

```powershell
cd api
python -m pip install -r requirements.txt
$env:DATABASE_URL = 'mysql+pymysql://USUARIO:SENHA@HOST_AIVEN:PORTA/BANCO_ATUAL?charset=utf8mb4&ssl_ca=certs/aiven-ca.pem&ssl_verify_cert=true&ssl_verify_identity=true'
$env:AUTO_CREATE_DATABASE = '0'
$env:AUTO_INIT_DB = '0'
python -m flask --app app init-db
```

Esse comando cria tabelas ausentes e executa as migrações aditivas existentes.
Faça backup antes de aplicar mudanças em um banco com dados. As funções na
Vercel não executam DDL em cada inicialização.

## 3. Publicar e conectar o aplicativo

Importe o repositório em Add New > Project na Vercel, selecione `Seniores/api` como
Root Directory, configure as variáveis acima e clique em Deploy.

Use o domínio resultante no Flutter, sem barra final e sem adicionar `/api`:

```powershell
cd front-end
flutter run --dart-define=API_URL=https://seu-projeto.vercel.app
# Para gerar o APK:
flutter build apk --dart-define=API_URL=https://seu-projeto.vercel.app
```

Execute os comandos a partir da raiz do repositório (ou ajuste o `cd`).
Valide cadastro, login, leitura e gravação com o aplicativo. A rota `/` retorna o nome da API e links para `/termos-de-uso` e
`/termo-consentimento`, acessíveis sem login. Caso Deployment
Protection esteja ativo, ajuste o acesso ao domínio usado pelo aplicativo.

## Limite de arquivos

A Vercel Functions limita o corpo da requisição/resposta a 4,5 MB. Embora a
API aceite anexos de até 10 MB, arquivos grandes e PDFs de relatórios acima
do limite não passam pela plataforma. Considere também o overhead de multipart
e base64. Para manter arquivos maiores, será necessário implementar upload e
download direto em armazenamento externo.

Referências: [Flask na Vercel](https://vercel.com/docs/frameworks/backend/flask)
e [limites das funções](https://vercel.com/docs/functions/limitations).

Conexão TLS: [certificados do Aiven](https://aiven.io/docs/platform/concepts/tls-ssl-certificates) e [PyMySQL no SQLAlchemy](https://docs.sqlalchemy.org/en/20/dialects/mysql.html#ssl-connections).

Os documentos são publicados pela API em JSON, com versão e contato. O consentimento
usa o PDF fornecido pela equipe; termos de uso mantêm o texto existente do aplicativo.
Identificações de responsáveis ainda não fornecidas permanecem pendentes nos textos.
