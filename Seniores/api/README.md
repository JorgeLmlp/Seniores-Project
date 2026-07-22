# Seniores API

API em Flask para cadastro e gerenciamento de usuarios do projeto Seniores.

O projeto esta organizado em camadas para separar responsabilidades: rotas recebem as chamadas HTTP, controllers montam as respostas, services cuidam das regras de negocio, repositories acessam o banco de dados e models representam as tabelas.

## Tecnologias

- Python
- Flask
- Flask-SQLAlchemy
- SQLite
- Werkzeug, usado para gerar hash de senha

## Como rodar

1. Instale as dependencias:

```bash
pip install -r requirements.txt
```

2. Rode a aplicacao:

```bash
python app.py
```

3. A API ficara disponivel em:

```text
http://127.0.0.1:5000
```

## Estrutura do projeto

```text
api/
|-- app.py
|-- extensions.py
|-- requirements.txt
|-- controllers/
|   |-- user_controller.py
|-- database/
|   |-- seniores.db
|   |-- create_database.sql
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
- configura o banco SQLite em `database/seniores.db`;
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

### database/

Guarda arquivos relacionados ao banco.

- `seniores.db`: banco SQLite usado pela API;
- `create_database.sql`: script SQL para criacao/consulta da estrutura do banco.

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

> Para um banco MySQL que ja existia antes deste recurso, execute uma vez o
> script `database/migrations/001_medicamentos_paciente.sql`. O
> `db.create_all()` cria tabelas novas, mas nao adiciona colunas a tabelas que
> ja existem.

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

## Observacoes

- O projeto usa SQLite local em `database/seniores.db`.
- As senhas sao salvas com hash, nao em texto puro.
- A pasta `.agents`, quando existir, nao faz parte da API Flask. Ela deve ser tratada como pasta de ferramenta/configuracao externa.
- A pasta `repositories` deve ser usada para consultas e alteracoes no banco.
- A pasta `services` deve ser usada para regras de negocio.
