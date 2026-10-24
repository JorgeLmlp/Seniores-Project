# Persistência do Flutter no MySQL

## Visão geral

Os formulários não gravam diretamente no MySQL. O Flutter envia JSON para a
API Flask; a API valida o usuário/paciente, usa SQLAlchemy e confirma a
transação no MySQL. A tela só retorna o novo item depois de receber uma resposta
HTTP `2xx`. Erros de conexão ou validação são exibidos por `SnackBar` e o
formulário permanece aberto.

```text
Flutter -> ApiService -> rota Flask -> service -> model SQLAlchemy -> MySQL
```

O login (`POST /users/login/`) devolve um JWT. Quando **Lembrar-me** está
marcado, o Flutter persiste a sessão e a restaura ao abrir o aplicativo. Todas
as chamadas privadas enviam `Authorization: Bearer <access_token>`. Registros
clínicos e organizacionais continuam vinculados ao paciente selecionado.

## O que é persistido

| Tela | Endpoint de criação | Tabela |
|---|---|---|
| Cadastro de conta | `POST /users/` | `pacientes`, `cuidadores` ou `responsaveis` |
| Medicamentos | `POST /pacientes/{id}/medicamentos` | `tbl_remedio` |
| Registro diário | `POST /pacientes/{id}/diarios-saude` | `diarios_saude` |
| Consultas | `POST /pacientes/{id}/consultas` | `registros_app` |
| Exames | `POST /pacientes/{id}/exames` | `registros_app` |
| Destinatários | `POST /pacientes/{id}/destinatarios` | `registros_app` |
| Comunicados | `POST /pacientes/{id}/comunicados` | `registros_app` |

`registros_app` mantém `paciente_id`, o nome do recurso, os dados JSON e as
datas de criação/alteração. Esse formato preserva todos os campos das telas em
evolução sem misturar esses contatos de agenda com as contas autenticáveis de
cuidadores, que exigem CPF, e-mail e senha.

Medicamentos agora também armazenam frequência, horários e alertas. O diário
mantém os níveis de 0 a 10, incidentes e dúvidas, além dos estados clínicos já
existentes (`bom`, `razoavel`, `ruim`, `pessimo`).

## Configuração local

### 1. MySQL e API

Na pasta `Seniores/api`:

```bash
cp .env.example .env
pip install -r requirements.txt
python app.py
```

Defina `DATABASE_URL` no `.env`, por exemplo:

```text
mysql+pymysql://usuario:senha@127.0.0.1:3306/db_seniores?charset=utf8mb4
```

A API sobe em `0.0.0.0:5001`. Na primeira inicialização, `create_all` cria as
tabelas ausentes. A migração aditiva em `extensions.py` acrescenta os novos
campos em instalações já existentes sem apagar registros.

### 2. Flutter

Na pasta `Seniores/front-end`:

```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:5001
```

Endereços usuais:

- Android Emulator: `http://10.0.2.2:5001` (já é o padrão);
- iOS Simulator, macOS ou web: `http://127.0.0.1:5001`;
- celular físico: `http://IP_DO_COMPUTADOR_NA_REDE:5001`.

Para produção, use HTTPS e informe a URL pública com `--dart-define`. HTTP sem
TLS está liberado somente nos manifests Android de debug/profile.

## Fluxo para validar manualmente

1. Inicie MySQL e a API.
2. Cadastre uma conta do tipo **Paciente**.
3. Faça login com a conta criada.
4. Cadastre um medicamento, diário, consulta ou outro item.
5. Feche e abra novamente a respectiva lista. A tela faz `GET` e reconstrói os
   itens retornados pelo banco.
6. Confira diretamente no MySQL, se necessário:

```sql
SELECT * FROM tbl_remedio ORDER BY id DESC;
SELECT * FROM diarios_saude ORDER BY id DESC;
SELECT id, paciente_id, recurso, dados FROM registros_app ORDER BY id DESC;
```

## Verificações automatizadas

```bash
cd Seniores/front-end/Seniores
flutter analyze
flutter test

cd ../../api
python -m compileall -q .
venv/bin/python -m unittest discover -s tests -v
```

Os testes Flutter verificam a serialização de medicamentos e diários e também
garantem que não seja possível criar um registro clínico sem paciente na
sessão. O teste da API cria dados temporários no MySQL configurado, confirma a
leitura por `GET` e remove os itens ao terminar.

## Autenticação e sessão

A API valida o JWT e o vínculo com o paciente em todas as rotas privadas. O
aplicativo descarta tokens expirados ao iniciar e encerra a sessão quando a API
responde `401`. Desmarcar **Lembrar-me** mantém a sessão apenas enquanto o
aplicativo estiver aberto; **Sair da conta** remove a sessão persistida.
