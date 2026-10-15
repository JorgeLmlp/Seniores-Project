# Seniores API

API REST em Flask para centralizar o acompanhamento de saúde e a rotina de
cuidados de pessoas idosas. O banco principal é MySQL e as respostas, exceto
arquivos, utilizam JSON.

## Funcionalidades

### 1. Perfil completo do idoso

O paciente possui os dados de usuário (`nome`, `email`, `telefone`, `cpf`) e os
campos específicos `idade`, `tipo_sanguineo` e `preferencias`. O tipo sanguíneo
aceita `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+` ou `O-`. Preferências são
armazenadas como JSON e podem conter, por exemplo, músicas e hobbies.

### 2. Cadastro de medicamentos

Cada medicamento pertence a um paciente e possui nome, dosagem, frequência,
horários, descrição, fabricante, lote e quantidade. A API oferece cadastro,
listagem, consulta, atualização e exclusão.

### 3. Alertas sonoros de medicação

O medicamento aceita `alerta_sonoro` e `som_alerta`, além da lista `alertas`.
A API persiste a configuração; o agendamento e a reprodução do som são feitos
pelo front-end ou pelo sistema operacional do dispositivo.

### 4. Confirmação da administração do remédio

Uma administração relaciona paciente e medicamento e registra
`horario_previsto`, `administrado_em`, `confirmado_por` e `observacao`. Isso
permite montar o histórico de doses efetivamente administradas.

### 5. Anotação de consultas futuras

A API não marca consultas em clínicas. Ela registra uma consulta futura com
médico, especialidade, local, data e hora, além de estados como concluída e
histórica.

### 6. Fotos e PDFs de exames

Arquivos JPEG, PNG, WebP ou PDF de até 10 MB podem ser anexados ao prontuário.
O conteúdo binário, nome e MIME type são persistidos e existe uma rota própria
para download.

### 7. Registro de sinais vitais

Registra pressão arterial, glicemia, temperatura, frequência cardíaca e
saturação, todos associados ao paciente e à data da medição.

### 8. Evolução dos sinais vitais

Um endpoint entrega `labels` cronológicas e séries separadas por medida,
formato que o front-end pode utilizar diretamente em gráficos.

### 9. Registro de incidentes

Quedas e outras intercorrências podem ser registradas com tipo, data e hora,
descrição, gravidade e providências adotadas.

### 10. Estoque de insumos

Controla itens como fraldas, gazes e luvas por nome, quantidade atual,
quantidade mínima e descrição.

### 11. Alertas de estoque baixo

Quando `quantidade <= quantidade_minima`, a API retorna um alerta no formato de
notificação. A exibição como push notification ou aviso na tela é
responsabilidade do front-end.

### 12. Relatório mensal consolidado em PDF

O relatório recebe mês e ano e reúne os acontecimentos do período: doses
administradas, sinais vitais, diário, incidentes, consultas, exames e documentos
anexados. Também inclui a situação vigente de medicamentos, dieta, contatos e
estoque. Sem período explícito, utiliza o mês atual.

### 13. Contatos de emergência

Mantém médicos e familiares com nome, tipo, vínculo, telefone, e-mail e
especialidade.

### 14. Botão de pânico

O botão é apresentado pelo front-end. A API registra cada acionamento com data
e hora, localização, mensagem e situação de resolução.

### 15. Diário de sintomas

Registra humor, dor, apetite, mobilidade e sono. Os níveis numéricos aceitam
valores de 0 a 10 e podem ser complementados por descrição, incidentes e
dúvidas.

### 16. Escala de turnos entre cuidadores

Registra cuidador, dias da semana, horário inicial, horário final e observação.
O projeto também preserva as rotas antigas de agenda `/cuidadores`, utilizadas
pelo aplicativo Flutter.

### 17. Preferências do idoso

Gostos musicais, hobbies e outras preferências são mantidos no objeto JSON
`preferencias` do paciente e podem ser alterados pelo endpoint de usuário.

### 18. Exportação do histórico por e-mail

A API gera o mesmo PDF mensal e o envia como anexo via SMTP. As credenciais e
o remetente são configurados por variáveis de ambiente; nenhuma senha de e-mail
fica no código.

### 19. Níveis de permissão

Permissões associam um paciente a um cuidador ou responsável e definem nível
`leitura` ou `escrita`. O membro informado é validado antes do cadastro.

### 20. Dieta e restrições alimentares

Registra descrição da dieta, lista de restrições, alergias e observações. O
recurso possui CRUD completo na API.

## Recursos complementares existentes

Além das vinte funcionalidades principais, a API mantém checklist de higiene,
acompanhamento de lesões com foto, registros financeiros, comunicados,
destinatários e relacionamentos entre pacientes, responsáveis e cuidadores.

## Arquitetura

O projeto segue o fluxo:

```text
Route -> Controller -> Service -> Repository/Model
```

- `routes`: registra URLs e métodos HTTP;
- `controllers`: interpreta request e monta response;
- `services`: valida dados e coordena regras de negócio;
- `repositories`: contém somente consultas, buscas, filtros e `SELECTs`;
- `models`: define as tabelas e executa inserções, atualizações, exclusões e
  transações.

Repositories não executam `add`, `delete`, `commit` ou `rollback`. Controllers
e services não possuem consultas SQLAlchemy diretamente.

## Estrutura principal

```text
api/
|-- app.py
|-- extensions.py
|-- controllers/
|-- models/
|-- repositories/
|-- routes/
|-- services/
|-- tests/
|-- README.md
|-- README_ENDPOINTS.md
|-- requirements.txt
```

## Tecnologias

- Python e Flask;
- Flask-SQLAlchemy e SQLAlchemy;
- MySQL com PyMySQL;
- Flask-CORS;
- Werkzeug para hash e verificação de senhas.

## Configuração

Crie o `.env` a partir do exemplo e configure a conexão MySQL:

```bash
cd api
pip install -r requirements.txt
cp .env.example .env
```

Variáveis principais:

```dotenv
DATABASE_URL=mysql+pymysql://usuario:senha@localhost:3306/seniores
DEBUG=0
```

Para exportação por e-mail:

```dotenv
SMTP_HOST=smtp.exemplo.com
SMTP_PORT=587
SMTP_FROM=seniores@exemplo.com
SMTP_USER=usuario
SMTP_PASSWORD=senha
SMTP_TLS=1
```

Execute a API:

```bash
python app.py
```

Por padrão, ela fica disponível em `http://127.0.0.1:5001`.

## Banco e migrações

Na inicialização, `db.create_all()` cria tabelas inexistentes e a migração
aditiva em `extensions.py` acrescenta colunas novas aos bancos anteriores sem
remover dados. SQLite é aceito somente em testes quando `API_TESTING=1`.

## Testes

A suíte `tests/test_todas_funcionalidades.py` possui um teste independente
para cada uma das 20 funcionalidades principais e mais três testes para login,
relacionamentos e recursos complementares. Ela verifica criação, listagem,
consulta, atualizações, exclusões, validações negativas, filtro mensal do PDF,
download de arquivos e montagem do e-mail com anexo. O SMTP é simulado nos
testes para que nenhuma mensagem real seja enviada.

Com um MySQL de testes configurado:

```bash
python -m unittest discover -s tests -v
```

Para execução isolada em SQLite:

```bash
API_TESTING=1 DATABASE_URL=sqlite:////tmp/seniores_test.sqlite \
python -m unittest discover -s tests -v
```

## Endpoints

A relação completa de endpoints, corpos e parâmetros está em
[README_ENDPOINTS.md](README_ENDPOINTS.md).
