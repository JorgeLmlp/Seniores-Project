# Endpoints da API Seniores

Base local: `http://127.0.0.1:5000`.

Todos os endpoints que recebem corpo usam JSON e devem ser enviados com o
header `Content-Type: application/json`.

## Usuarios

### `POST /cuidador`

Cria um cuidador. O corpo deve conter `nome`, `email`, `senha`, `telefone`,
`cpf` e `tipo: "cuidador"`.

### `POST /paciente`

Cria um paciente. Use os mesmos campos de usuario e `tipo: "paciente"`.

### `POST /responsavel`

Cria um responsavel. Use os mesmos campos de usuario e `tipo: "responsavel"`.

### `POST /users/`

Cria um usuario de qualquer tipo. O campo `tipo` define se o cadastro sera de
`paciente`, `cuidador` ou `responsavel`.

Exemplo:

```json
{
  "nome": "Maria da Silva",
  "email": "maria@example.com",
  "senha": "Senha@123",
  "telefone": "11999999999",
  "cpf": "12345678901",
  "tipo": "paciente"
}
```

### `GET /users/`

Lista todos os usuarios cadastrados.

### `GET /users/?tipo={tipo}`

Lista apenas usuarios do tipo informado: `paciente`, `cuidador` ou
`responsavel`.

### `GET /users/?tipo=paciente&cuidador_id={cuidador_id}`

Lista todos os pacientes vinculados ao cuidador informado, devolvendo os dados
completos de cada paciente. Por exemplo: `GET /users/?tipo=paciente&cuidador_id=3`.

### `GET /users/{tipo}/{usuario_id}/`

Busca um usuario pelo seu tipo e ID.

### `PUT /users/{tipo}/{usuario_id}/`
### `PATCH /users/{tipo}/{usuario_id}/`

Atualiza os campos enviados de um usuario. Aceita, entre outros, `nome`,
`email`, `telefone`, `cpf` e `senha`.

### `DELETE /users/{tipo}/{usuario_id}/`

Remove o usuario informado.

Ao consultar um cuidador (por `GET /users/?tipo=cuidador` ou por ID), a resposta
inclui `pacientes_ids` e `pacientes`, uma lista com os dados completos de todos
os pacientes vinculados a ele.

### `POST /users/login/`

Autentica pelo e-mail e senha. O campo `tipo` e opcional; quando informado,
aceita `paciente`, `responsavel` ou `cuidador`.

```json
{
  "email": "verificacao.paciente01@seniores.local",
  "senha": "SenhaTeste123!"
}
```

Retorna o usuario sem a senha. Credenciais invalidas retornam `401`.

## Relacionamentos

### `POST /registrar_relacionamento`

Vincula um paciente a um responsavel e o define como responsavel principal do
paciente. Tambem preserva o vinculo N:N entre paciente e responsavel.

```json
{
  "cpfPaciente": "12345678901",
  "cpfResponsavel": "98765432100"
}
```

### `POST /relacionamentos/paciente-cuidador`

Vincula um paciente a um cuidador. A relacao e N:1: cada paciente tem um
cuidador, enquanto o mesmo cuidador pode acompanhar varios pacientes.

```json
{
  "cpfPaciente": "12345678901",
  "cpfCuidador": "98765432100"
}
```

### `POST /relacionamentos/cuidador-responsavel`

Cria um vinculo entre cuidador e responsavel. A relacao e N:N, portanto cada
cuidador pode ter varios responsaveis e vice-versa.

```json
{
  "cpfCuidador": "98765432100",
  "cpfResponsavel": "98765432101"
}
```

## Medicamentos

### `POST /pacientes/{paciente_id}/medicamentos`

Cadastra um medicamento para o paciente. `nome` e `dosagem` sao obrigatorios;
tambem aceita `descricao`, `fabricante`, `lote` e `quantidade`.

```json
{
  "nome": "Losartana",
  "dosagem": "50 mg",
  "quantidade": 30
}
```

### `GET /pacientes/{paciente_id}/medicamentos`

Lista os medicamentos associados ao paciente.

### `GET /medicamentos/{medicamento_id}`

Busca os dados de um medicamento pelo ID.

### `PUT /medicamentos/{medicamento_id}`
### `PATCH /medicamentos/{medicamento_id}`

Atualiza os campos enviados de um medicamento.

### `DELETE /medicamentos/{medicamento_id}`

Exclui o medicamento informado.

## Sinais vitais

### `POST /sinais-vitais`

Cria um registro de sinais vitais. Informe pelo menos uma medida. O campo
`data` e opcional e, quando enviado, deve usar o formato ISO 8601.

```json
{
  "freq_cardiaca": "72 bpm",
  "saturacao": "98%",
  "pressao_art": "120/80 mmHg",
  "glicemia": "102 mg/dL",
  "temperatura": "36.6 C"
}
```
