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

### `GET /users/?tipo=paciente&responsavel_id={responsavel_id}`

Lista os pacientes vinculados ao responsável informado.

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

Retorna o usuario sem a senha e um token de sessão assinado, válido por oito
horas. Credenciais invalidas retornam `401`. As demais rotas protegidas devem
receber `Authorization: Bearer {token}`.

O paciente pode acessar e administrar os próprios dados e vínculos. Um
responsável ou cuidador só pode acessar dados de pacientes vinculados a ele;
requisições sem sessão retornam `401` e vínculos inválidos retornam `403`.

### `POST /users/password-reset/request`

Solicita a recuperação pelo e-mail. A resposta é genérica para não revelar se o
endereço está cadastrado. Com `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`,
`SMTP_PASSWORD` e `PASSWORD_RESET_FROM` configurados, a API envia um link com
token válido por 15 minutos.

### `POST /users/password-reset/confirm`

Redefine a senha com o token recebido e uma nova senha de pelo menos seis
caracteres. Cada token é invalidado após o primeiro uso.

```json
{
  "token": "token-recebido-por-e-mail",
  "nova_senha": "NovaSenha@123"
}
```

## Relacionamentos

### `POST /historico/email`

Envia por SMTP um resumo textual do histórico diário do paciente. Recebe
`paciente_id` e `email`; o endereço é validado e o servidor SMTP precisa estar
configurado no ambiente da API.

```json
{
  "paciente_id": 1,
  "email": "destino@example.com"
}
```

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
tambem aceita `frequencia`, `horarios`, `alertas`, `descricao`, `fabricante`,
`lote`, `quantidade`, `alerta_sonoro` e `som_alerta`.

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

### Fotos e administrações de medicamentos

- `POST`, `GET` e `DELETE /medicamentos/{medicamento_id}/foto`: envia, abre ou
  remove uma foto JPEG, PNG ou WebP de até 5 MB usando o campo multipart `foto`.
- `GET` e `POST /medicamentos/{medicamento_id}/administracoes`: lista ou
  registra uma dose confirmada com horário, responsável e observação.
- `PATCH` e `DELETE /administracoes-medicamentos/{administracao_id}`: altera ou
  remove uma confirmação de dose.

## Documentos de exames

- `GET` e `POST /exames/{exame_id}/documentos`: lista ou recebe o multipart
  `arquivo` nos formatos PDF, JPEG, PNG e WebP, com limite de 10 MB.
- `GET /documentos-exame/{documento_id}/arquivo`: abre ou baixa o arquivo.
- `DELETE /documentos-exame/{documento_id}`: exclui o documento e o arquivo
  armazenado.

## Consultas

### `POST /pacientes/{paciente_id}/consultas`
### `GET /pacientes/{paciente_id}/consultas`

Criam ou listam consultas do paciente. Para criar, `titulo` e `data` sao
obrigatorios; tambem podem ser enviados `especialidade`, `profissional`,
`hora`, `local`, `telefone` e `observacoes`.

### `GET /consultas/{consulta_id}`
### `PUT/PATCH /consultas/{consulta_id}`
### `DELETE /consultas/{consulta_id}`

Consultam, alteram ou excluem uma consulta.

## Exames

### `POST /pacientes/{paciente_id}/exames`
### `GET /pacientes/{paciente_id}/exames`

Criam ou listam exames do paciente. `nome` e `data` sao obrigatorios; tambem
aceita `laboratorio`, `local`, `observacoes` e `documento_url`.

### `GET /exames/{exame_id}`
### `PUT/PATCH /exames/{exame_id}`
### `DELETE /exames/{exame_id}`

Consultam, alteram ou excluem um exame.

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

## Rotinas clínicas

### `POST /pacientes/{paciente_id}/higiene`
### `GET /pacientes/{paciente_id}/higiene`

Criam ou listam checklists de higiene persistidos para o paciente. O corpo
deve conter `tipo`, `data_hora` e um objeto `itens` com pelo menos um item
booleano; `observacoes` é opcional.

### `GET /higiene/{higiene_id}`
### `PUT/PATCH /higiene/{higiene_id}`
### `DELETE /higiene/{higiene_id}`

Consultam, alteram ou excluem uma rotina de higiene.

### `POST /pacientes/{paciente_id}/lesoes`
### `GET /pacientes/{paciente_id}/lesoes`

Criam ou listam prontuários de lesões. `localizacao`, `data_inicio` e
`descricao` são obrigatórios; `evolucao` é opcional.

### `GET /lesoes/{lesao_id}`
### `PUT/PATCH /lesoes/{lesao_id}`
### `DELETE /lesoes/{lesao_id}`

Consultam, alteram ou excluem uma lesão.

- `POST`, `GET` e `DELETE /lesoes/{lesao_id}/foto`: enviam, abrem ou removem
  uma foto JPEG, PNG ou WebP de até 5 MB usando o campo multipart `foto`.

### `POST /pacientes/{paciente_id}/dietas`
### `GET /pacientes/{paciente_id}/dietas`

Criam ou listam dietas e restrições alimentares. `tipo`, `data_inicio` e
`descricao` são obrigatórios; `restricoes`, `observacoes` e `ativa` são
opcionais.

### `GET /dietas/{dieta_id}`
### `PUT/PATCH /dietas/{dieta_id}`
### `DELETE /dietas/{dieta_id}`

Consultam, alteram, ativam/desativam ou excluem uma dieta.
