# Seniores API

API REST em Flask para cadastro de usuarios e gerenciamento dos cuidados de
pacientes do projeto Seniores.

O projeto esta organizado em camadas para separar responsabilidades: rotas
recebem as chamadas HTTP, controllers montam as respostas, services cuidam das
regras de negocio, repositories acessam o banco de dados e models representam
as tabelas.

## Principais funcionalidades

1. **Cadastro de usuarios por perfil:** permite cadastrar pacientes, cuidadores
   e responsaveis, com validacao dos campos obrigatorios.
2. **Autenticacao de usuarios:** realiza login por e-mail e senha, com filtro
   opcional pelo tipo de usuario.
3. **Protecao de senhas:** armazena as senhas como hash do Werkzeug e nunca as
   devolve nas respostas da API.
4. **Gerenciamento completo de usuarios:** oferece operacoes para criar, listar,
   consultar, atualizar e excluir usuarios.
5. **Filtro de usuarios:** permite filtrar a listagem por perfil e consultar os
   pacientes vinculados a um cuidador.
6. **Relacionamento entre paciente e responsavel:** vincula o paciente ao seu
   responsavel principal e mantem a relacao entre os dois.
7. **Relacionamento entre paciente e cuidador:** associa cada paciente a um
   cuidador, que pode acompanhar varios pacientes.
8. **Relacionamento entre cuidadores e responsaveis:** mantem vinculos muitos
   para muitos entre esses dois perfis.
9. **Controle de medicamentos:** cadastra, lista, consulta, atualiza e remove os
   medicamentos associados a cada paciente.
10. **Monitoramento de sinais vitais:** registra historicos de frequencia
    cardiaca, saturacao, pressao arterial, glicemia e temperatura.
11. **Diario de saude:** acompanha humor, dor, fome e mobilidade do paciente,
    com descricao opcional de cada registro.
12. **Checklist de higiene:** organiza tarefas recorrentes e permite controlar
    se cada atividade esta pendente ou concluida.
13. **Controle de estoque:** registra itens, quantidades disponiveis e quantidade
    minima para os cuidados do paciente.
14. **Acompanhamento de lesoes:** registra localizacao, descricao, gravidade,
    status e foto da lesao em JPEG, PNG, WebP ou GIF.
15. **Registros financeiros:** controla receitas e despesas relacionadas ao
    paciente, incluindo valor, descricao e data.
16. **Integracao com clientes web:** disponibiliza CORS para consumo da API por
    aplicacoes como o frontend Flutter Web.

## Tecnologias

- Python
- Flask
- Flask-SQLAlchemy
- MySQL
- PyMySQL
- Flask-CORS
- Werkzeug, usado para gerar hash de senha

## Como rodar

1. Entre na pasta da API e instale as dependencias:

```bash
cd api
pip install -r requirements.txt
```

2. Crie o arquivo de configuracao local a partir do exemplo:

```bash
cp .env.example .env
```

Edite `DATABASE_URL` no arquivo `.env` com as credenciais do seu MySQL. O
usuario configurado deve ter permissao para criar o banco caso ele ainda nao
exista.

3. Rode a aplicacao:

```bash
python app.py
```

4. A API ficara disponivel em:

```text
http://127.0.0.1:5001
```

## Estrutura do projeto

```text
api/
|-- app.py
|-- extensions.py
|-- requirements.txt
|-- controllers/
|   |-- user_controller.py
|-- models/
|   |-- cuidador.py
|   |-- paciente.py
|   |-- responsavel.py
|   |-- remedio.py
|-- repositories/
|   |-- user_repository.py
|-- routes/
|   |-- home.py
|   |-- registrar.py
|   |-- usuarios.py
|-- services/
|   |-- User_services.py
```

## Papel de cada parte

### app.py

Arquivo principal para iniciar a API.

Ele importa o `app` configurado em `extensions.py` e executa o servidor Flask em modo debug quando o arquivo e rodado diretamente.

### extensions.py

Centraliza a criacao do Flask e do SQLAlchemy.

Neste arquivo o projeto:

- cria a instancia `db`;
- cria a instancia `app`;
- configura o MySQL pela variável `DATABASE_URL`;
- registra os blueprints de `routes`;
- cria as tabelas com `db.create_all()`.

### routes/

Define as URLs da API e conecta cada rota a uma funcao do controller.

Arquivos principais:

- `home.py`: cria a rota `/`, que retorna `"teste"`;
- `usuarios.py`: cria as rotas principais de usuarios;
- `registrar.py`: cria a rota `/registrar_cuidador/`;
- `__init__.py`: junta os blueprints e exporta a lista `blueprints`.

### controllers/

Recebe as requisicoes HTTP e devolve respostas JSON.

O controller nao deve acessar o banco diretamente. Ele chama o service, interpreta o status retornado e monta a resposta correta.

Exemplo: `controllers/user_controller.py` recebe dados do `request`, chama `UserService` e retorna mensagens como:

- usuario criado;
- usuario nao encontrado;
- tipo de usuario invalido;
- email ou CPF ja cadastrado.

### services/

Guarda as regras de negocio.

O arquivo `services/User_services.py` valida os dados recebidos, decide qual status deve ser retornado, gera hash da senha e chama o repository para acessar o banco.

Exemplos de regras que ficam no service:

- verificar se os dados obrigatorios foram enviados;
- validar o tipo de usuario;
- impedir cadastro duplicado por email ou CPF;
- gerar hash da senha antes de salvar;
- decidir se o retorno sera `201`, `400`, `404`, `409` ou `204`.

### repositories/

Guarda o codigo que acessa o banco de dados.

O arquivo `repositories/user_repository.py` concentra as consultas e alteracoes no banco, como:

- buscar classe por tipo de usuario;
- verificar se email ou CPF ja existe;
- criar usuario;
- listar usuarios;
- buscar usuario por id;
- salvar alteracoes;
- deletar usuario.

Essa camada evita que o service fique cheio de consultas SQLAlchemy.

### models/

Define as tabelas e entidades do banco.

Arquivos principais:

- `cuidador.py`: define a classe base `Usuario` e o model `Cuidador`;
- `paciente.py`: define `Paciente`, `SinalVital` e `LstSinaisVit`;
- `responsavel.py`: define `Responsavel`;
- `remedio.py`: define o model relacionado a remedios;
- `__init__.py`: importa os models para que o SQLAlchemy consiga registra-los.

### Banco de dados

O banco é MySQL e sua conexão é definida por `DATABASE_URL`. As tabelas
inexistentes são criadas pelo SQLAlchemy; migrações aditivas para instalações
anteriores são executadas na inicialização por `extensions.py`.

## Fluxo de uma requisicao

Exemplo: criar um usuario.

```text
Cliente faz POST /users/
        |
        v
routes/usuarios.py chama criar_usuario
        |
        v
controllers/user_controller.py le o JSON da requisicao
        |
        v
services/User_services.py valida os dados e aplica regras
        |
        v
repositories/user_repository.py salva no banco
        |
        v
controller devolve JSON com status HTTP
```

## Endpoints atuais

### Home

```http
GET /
```

Retorna:

```text
teste
```

### Criar usuario

```http
POST /users/
```

Tambem existe:

```http
POST /registrar_cuidador/
```

Corpo esperado:

```json
{
  "nome": "Maria",
  "email": "maria@email.com",
  "senha": "123456",
  "telefone": "11999999999",
  "cpf": "12345678900",
  "tipo": "cuidador"
}
```

Tipos aceitos:

- `cuidador`
- `paciente`
- `responsavel`

### Listar usuarios

```http
GET /users/
```

Para listar apenas um tipo:

```http
GET /users/?tipo=cuidador
```

### Buscar usuario por id

```http
GET /users/<tipo>/<usuario_id>/
```

Exemplo:

```http
GET /users/cuidador/1/
```

### Atualizar usuario

```http
PUT /users/<tipo>/<usuario_id>/
PATCH /users/<tipo>/<usuario_id>/
```

Exemplo:

```http
PATCH /users/paciente/2/
```

Corpo possivel:

```json
{
  "nome": "Novo nome",
  "telefone": "11888888888"
}
```

### Deletar usuario

```http
DELETE /users/<tipo>/<usuario_id>/
```

Exemplo:

```http
DELETE /users/responsavel/3/
```

## Codigos de resposta usados

- `200`: operacao realizada com sucesso;
- `201`: usuario criado com sucesso;
- `204`: usuario deletado com sucesso;
- `400`: dados obrigatorios ausentes ou tipo invalido;
- `404`: usuario nao encontrado;
- `409`: ja existe usuario com o mesmo email ou CPF.

## Medicamentos do paciente

### Cadastrar e relacionar medicamento

```http
POST /pacientes/<paciente_id>/medicamentos
```

```json
{
  "nome": "Losartana",
  "dosagem": "50 mg",
  "descricao": "Tomar uma vez ao dia",
  "fabricante": "Exemplo Farma",
  "lote": "L123",
  "quantidade": 30
}
```

`nome` e `dosagem` sao obrigatorios. O `paciente_id` na URL cria o vinculo com o paciente.

### Modelo de medicamento

As respostas de cadastro, consulta e alteracao retornam o medicamento neste formato:

```json
{
  "id": 1,
  "paciente_id": 2,
  "nome": "Losartana",
  "descricao": "Tomar uma vez ao dia",
  "dosagem": "50 mg",
  "fabricante": "Exemplo Farma",
  "lote": "L123",
  "quantidade": 30
}
```

- `id`: identificador do medicamento.
- `paciente_id`: identificador do paciente ao qual o medicamento pertence.
- `nome` e `dosagem`: campos obrigatorios.
- `descricao`, `fabricante`, `lote` e `quantidade`: campos opcionais.

> Bancos MySQL existentes recebem as novas colunas pela migração aditiva de
> `extensions.py` quando a API é iniciada. Nenhuma coluna ou dado é removido.

### Exibir a lista de medicamentos

```http
GET /pacientes/<paciente_id>/medicamentos
```

### Consultar, alterar ou excluir um medicamento

```http
GET    /medicamentos/<medicamento_id>
PATCH  /medicamentos/<medicamento_id>
PUT    /medicamentos/<medicamento_id>
DELETE /medicamentos/<medicamento_id>
```

## Login

```http
POST /users/login/
Content-Type: application/json
```

```json
{
  "email": "maria@example.com",
  "senha": "Senha@123",
  "tipo": "paciente"
}
```

`tipo` e opcional e pode ser `paciente`, `cuidador` ou `responsavel`. Quando
nao informado, a busca e feita entre todos os tipos de usuario. O retorno e o
usuario autenticado sem o campo de senha. Credenciais invalidas retornam
`401`; corpo ausente, incompleto ou com tipo invalido retorna `400`.

As senhas sao persistidas somente como hash do Werkzeug. O login usa
`check_password_hash` para comparar a senha recebida com o hash salvo; hashes
nao sao descriptografados nem enviados na resposta.

## Sinais vitais do paciente

Cada sinal vital pertence a um paciente. `data` e opcional e deve estar no
formato ISO 8601. Informe ao menos uma das medidas: `freq_cardiaca`,
`saturacao`, `pressao_art`, `glicemia` ou `temperatura`.

```http
POST   /pacientes/<paciente_id>/sinais-vitais
GET    /pacientes/<paciente_id>/sinais-vitais
GET    /sinais-vitais/<sinal_vital_id>
PUT    /sinais-vitais/<sinal_vital_id>
PATCH  /sinais-vitais/<sinal_vital_id>
DELETE /sinais-vitais/<sinal_vital_id>
```

Exemplo de cadastro:

```json
{
  "pressao_art": "120/80 mmHg",
  "temperatura": "36.5 C",
  "data": "2026-08-12T10:30:00"
}
```

## Registros do paciente

Os registros abaixo usam o mesmo padrao: `POST` cria e `GET` lista na rota do
paciente; as operacoes sobre um item usam sua rota por ID.

| Recurso | Colecao | Item |
| --- | --- | --- |
| Diario de saude | `/pacientes/<paciente_id>/diarios-saude` | `/diarios-saude/<registro_id>` |
| Checklist de higiene | `/pacientes/<paciente_id>/checklists-higiene` | `/checklists-higiene/<registro_id>` |
| Estoque | `/pacientes/<paciente_id>/estoque` | `/estoque/<registro_id>` |
| Lesoes | `/pacientes/<paciente_id>/lesoes` | `/lesoes/<registro_id>` |
| Registro financeiro | `/pacientes/<paciente_id>/registros-financeiros` | `/registros-financeiros/<registro_id>` |

Para cada recurso, as rotas disponiveis sao:

```http
POST   <colecao>
GET    <colecao>
GET    <item>
PUT    <item>
PATCH  <item>
DELETE <item>
```

Um `paciente_id` inexistente retorna `404` ao criar ou listar. Um ID de
registro inexistente tambem retorna `404`. Dados ausentes ou invalidos retornam
`400`; erros de persistencia retornam `500`.

### Diario de saude

Campos obrigatorios: `humor`, `dor`, `fome` e `mobilidade`. Cada um aceita
`bom`, `ruim`, `pessimo` ou `razoavel`. `descricao` e opcional.

```json
{
  "humor": "bom",
  "dor": "razoavel",
  "fome": "bom",
  "mobilidade": "ruim",
  "descricao": "Caminhou com auxilio."
}
```

### Checklist de higiene

Campos obrigatorios: `tarefa`, `descricao` e `frequencia`. O campo opcional
`status` aceita `pendente` (padrao) ou `concluida`.

```json
{
  "tarefa": "Banho",
  "descricao": "Auxiliar no banho da manha",
  "frequencia": "diaria",
  "status": "pendente"
}
```

### Estoque

Campos obrigatorios: `nome` e `quantidade`. `quantidade` e
`quantidade_minima` devem ser inteiros nao negativos. `descricao` e opcional.

```json
{
  "nome": "Luvas descartaveis",
  "quantidade": 50,
  "quantidade_minima": 10
}
```

### Lesoes e fotos

Campos obrigatorios: `localizacao` e `descricao`. Tambem aceita `gravidade` e
`status` (o padrao e `aberta`). A foto e opcional e fica armazenada no banco.
Envie-a em `foto_base64`, como Base64 puro com `foto_mime` ou como data URL.
Sao aceitos JPEG, PNG, WebP e GIF, ate 5 MB.

```json
{
  "localizacao": "Braco esquerdo",
  "descricao": "Escoriacao superficial",
  "gravidade": "leve",
  "foto_base64": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

As respostas de lesao retornam `foto_url` quando houver imagem, sem incluir o
conteudo Base64. Use a rota abaixo para obter o arquivo com o `Content-Type`
correto:

```http
GET /lesoes/<registro_id>/foto
```

Para remover somente a foto durante uma atualizacao, envie:

```json
{ "foto_base64": null }
```

### Registro financeiro

Campos obrigatorios: `descricao`, `valor` e `tipo`. `tipo` aceita apenas
`receita` ou `despesa`; `valor` deve ser numerico e nao negativo. `data` e
opcional e, quando enviada, usa ISO 8601.

```json
{
  "descricao": "Compra de medicamentos",
  "valor": 89.90,
  "tipo": "despesa",
  "data": "2026-08-12T10:30:00"
}
```

## Observacoes

- O projeto usa MySQL, configurado pela variavel `DATABASE_URL` no arquivo
  `.env`.
- As senhas sao salvas com hash, nao em texto puro.
- A lista detalhada de rotas tambem esta disponivel em
  [`README_ENDPOINTS.md`](README_ENDPOINTS.md).
- Para bancos ja existentes, a inicializacao aplica uma migracao aditiva das
  colunas de foto de lesoes (`foto` e `foto_mime`).
- A pasta `.agents`, quando existir, nao faz parte da API Flask. Ela deve ser tratada como pasta de ferramenta/configuracao externa.
- A pasta `repositories` deve ser usada para consultas e alteracoes no banco.
- A pasta `services` deve ser usada para regras de negocio.
