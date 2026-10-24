# Execução local

Na pasta `api`, execute `python app.py`. A API usa a porta 5001 e carrega o
`.env` dessa pasta, mesmo quando iniciada por outro diretório. A conexão MySQL
configurada foi verificada sem modificar as credenciais.

Para usar um banco local da API, configure explicitamente
`DATABASE_URL=sqlite:///seniores-local.db`. Isso cria outro banco, sem copiar os
dados existentes do MySQL. Sem DATABASE_URL, esse é o padrão local. Uma falha
de MySQL não provoca troca automática de banco.

Na pasta `front-end`:

```powershell
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:5001
```

O Device Preview fica habilitado em desenvolvimento e desabilitado em release.
O tema padrão é claro; uma preferência escolhida nas configurações é preservada.

No emulador Android, a URL padrão é `http://10.0.2.2:5001`. Em um celular físico,
use o IP do computador na rede em `API_URL`.

O login retorna um JWT; as solicitações e os registros validam a conta
autenticada. Configure uma `JWT_SECRET_KEY` estável e privada no `.env`. Quando
**Lembrar-me** está marcado, a sessão é restaurada ao abrir o aplicativo. Tokens
expirados ou rejeitados pela API são removidos automaticamente.

## Fluxos

- Responsável: abra **Pacientes e vínculos**, vincule um paciente cadastrado por
  CPF e use **Convidar por e-mail** no cartão desse paciente. Informe o e-mail
  cadastrado na conta do cuidador.
- Cuidador: abra **Meus pacientes**, examine o responsável e o paciente na
  solicitação e aceite ou recuse. Após aceitar, selecione o paciente para abrir
  seus cuidados. A API não permite acessar pacientes sem vínculo.
- Medicamentos: **Detalhes** permite editar o cadastro e alternar cada dose
  entre concluída e não concluída. O estado pertence à data e ao horário da dose.
- Relatórios: o menu **Relatórios** baixa o PDF mensal da API; o gráfico do
  diário usa os níveis numéricos registrados, sem dados de demonstração.
- Conta: **Minha conta** atualiza nome, e-mail, telefone e senha. **Configurações**
  permite escolher tema claro, escuro ou do sistema e limpar dados temporários.
- **Sair da conta** remove a sessão, os rascunhos e o cache da conta e retorna
  ao login sem permitir voltar às telas anteriores.

## Armazenamento temporário

O SQLite do aplicativo guarda rascunhos de medicamentos, consultas, exames,
gastos, diário, destinatários e comunicados. As chaves incluem conta, paciente
e formulário. Um salvamento confirmado pela API limpa o rascunho correspondente.
Listas recebidas da API também são copiadas para o cache. A API continua sendo
a fonte de verdade; falhas de gravação são apresentadas ao usuário.

Esse armazenamento não é uma fila de sincronização offline: cadastrar ou
alterar registros definitivos exige conexão com a API. No navegador, os arquivos
`web/sqlite3.wasm` e `web/sqflite_sw.js` precisam ser servidos junto com a aplicação.
O suporte Web segue a implementação do pacote
[sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).
O download/compartilhamento do PDF usa o pacote
[printing](https://pub.dev/packages/printing).

## Testes

Instale as dependências da API com `python -m pip install -r requirements.txt`.
O PDF utiliza ReportLab para tabelas, quebra de texto, cabeçalhos e paginação.
Para executar também os testes que extraem e verificam o conteúdo dos PDFs,
use `python -m pip install -r requirements-test.txt` na pasta `api`.

API, usando um banco isolado em memória:

```powershell
$env:DATABASE_URL='sqlite:///:memory:'
$env:API_TESTING='1'
python -m unittest discover -s tests
```

`API_TESTING=1` mantém compatibilidade com os testes históricos sem token.
Não use essa variável ao iniciar a aplicação normal. Os novos testes enviam
tokens e verificam permissões, convites, recusa, consulta sem exame, gastos,
doses por data, edição de conta e PDF com múltiplas páginas.

Flutter:

```powershell
flutter analyze --no-fatal-infos
flutter test
flutter build web
```

Os testes de telas verificam abertura em tamanho de celular com tema escuro.
Os testes de fluxo verificam rascunhos SQLite, isolamento entre contas, mensagens
de erro da API, apresentação dos convites, locale pt-BR e horário de 24 horas.
