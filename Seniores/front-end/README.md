# Seniores Front-end

Aplicativo em Flutter para centralizar a interface do usuário, interações locais e a rotina de cuidados de pessoas idosas, integrando-se à API REST principal.
## Funcionalidades

### 1. Login e autenticação
 é a funcionalidade responsável por permitir que os usuários acessem o aplicativo por meio de suas credenciais. Ela constitui uma das principais etapas de entrada no sistema, identificando o usuário antes de disponibilizar as áreas que exigem autenticação. a interface apresenta campos para o preenchimento do e-mail e da senha.

### 2. Cadastro de usuários
 é a funcionalidade que permite criar novas contas para as pessoas que utilizarão o Seniores, reunindo as informações necessárias para identificar cada usuário. 
 
### 3. Perfil do idoso
 é a área destinada à apresentação das informações pessoais e dos dados relevantes para o acompanhamento de cada paciente. A interface consulta os dados disponibilizados pela API e apresenta informações como nome, e-mail, telefone, CPF, idade e tipo sanguíneo.

### 4. Gerenciamento de medicamentos
 é a funcionalidade responsável por apresentar e organizar os medicamentos utilizados pelo idoso, incluindo suas informações de identificação e administração. A tela de medicamentos pode exibir uma lista com nome, dosagem, frequência, horários e descrição de cada item.

### 5. Alertas sonoros de medicação
 é o recurso destinado a auxiliar o usuário a lembrar os horários previstos para a administração dos medicamentos. A interface apresenta os horários cadastrados e as configurações de alerta de cada medicamento.
 
### 6. Confirmação da administração de medicamentos
 é a funcionalidade que permite registrar se uma dose prevista foi efetivamente administrada ao paciente. A interface apresenta os medicamentos e suas informações de horário. Quando a confirmação está disponível, o usuário pode indicar que a dose foi administrada e, se necessário, registrar uma observação.

### 7. Agendamento e acompanhamento de consultas
 é a funcionalidade que organiza as informações das consultas médicas futuras do paciente. O aplicativo pode apresentar uma lista de consultas com nome do médico, especialidade, local, data e horário. Por meio de formulários, os usuários autorizados podem cadastrar novas consultas ou modificar informações existentes, conforme os recursos implementados. 
 
### 8. Prontuário de exames
 é a área destinada à organização e à consulta de arquivos relacionados aos exames médicos do paciente. A interface pode apresentar uma lista de documentos disponíveis e suas informações, como nome e tipo de arquivo. Quando o envio está implementado, o usuário pode selecionar uma fotografia ou um documento PDF e encaminhá-lo à API. Para visualizar um documento, o aplicativo pode solicitar o download do arquivo e abri-lo em um visualizador compatível.

### 9. Gráficos de evolução da saúde
 é o recurso visual que transforma os registros de sinais vitais em representações gráficas, facilitando a comparação das medições ao longo do tempo. O aplicativo utiliza os dados históricos disponibilizados pela API, que podem incluir uma sequência cronológica de datas e séries separadas para cada medida.
 
### 10. Registro de incidentes
 é a funcionalidade destinada ao registro de ocorrências relevantes na rotina do idoso, como quedas, acidentes e outras intercorrências. A interface apresenta um formulário para registrar o tipo de incidente, a data, o horário, a descrição, a gravidade e as providências adotadas.
 
### 11. Visualização de relatórios mensais
 é a funcionalidade que permite consultar um resumo dos acontecimentos relacionados à rotina de cuidados durante determinado mês. O usuário pode selecionar o período desejado, quando essa opção estiver disponível, e solicitar o relatório à API. O documento gerado pode reunir informações sobre doses administradas, sinais vitais, diário de sintomas, incidentes, consultas, exames, documentos anexados e situação atual de medicamentos e estoque. A interface permite acessar ou visualizar o PDF conforme os recursos implementados.

### 12. Exportação e compartilhamento de relatórios
 é o recurso que permite disponibilizar os relatórios gerados pelo sistema para consulta ou compartilhamento. O front-end solicita à API a geração do relatório mensal e disponibiliza o arquivo PDF ao usuário. Quando o envio por e-mail está integrado à interface, o aplicativo pode oferecer uma ação para solicitar o envio do documento como anexo. O servidor realiza o envio utilizando as configurações de e-mail definidas em seu ambiente.

### 13. Contatos de emergência
é a funcionalidade que apresenta os contatos de pessoas que podem ser importantes durante a rotina de assistência ao idoso. A interface exibe informações como nome, tipo de contato, vínculo com o paciente, telefone, e-mail e especialidade, quando aplicável. 

### 14. Diário de sintomas
 é a funcionalidade que permite registrar informações sobre o estado físico e o bem-estar do idoso ao longo dos dias. A interface apresenta campos para informar humor, dor, apetite, mobilidade e qualidade do sono. Os níveis numéricos podem variar de 0 a 10, de acordo com o campo, e podem ser complementados por uma descrição, dúvidas ou informações sobre incidentes.
 
### 15. Escala de turnos dos cuidadores
 é a funcionalidade destinada à organização dos horários e dos dias de trabalho dos cuidadores responsáveis pelo atendimento ao paciente. A interface apresenta os turnos cadastrados, incluindo o nome do cuidador, os dias da semana, o horário de início, o horário de término e as observações. 
 
### 16. Preferências do idoso
 é o recurso que apresenta informações sobre os gostos, interesses e preferências pessoais do paciente. A interface consulta o objeto de preferências associado ao perfil do idoso, que pode conter informações como músicas favoritas, hobbies e outras atividades de interesse.

## Recursos complementares da interface

Além das funcionalidades principais, o front-end pode utilizar componentes de carregamento, atualização de listas, confirmação de operações e tratamento de falhas de conexão. Esses recursos ajudam a tornar as interações mais claras e a manter a interface coerente com o estado dos dados recebidos da API.

## Arquitetura do front-end
- **Pages:** concentram as telas e os fluxos de interação, como login, início, cadastro e medicamentos.
- **Widgets:** contêm componentes reutilizáveis, como campos de texto, botões, cartões e menus.
- **Services:** concentram a comunicação com a API REST e operações relacionadas à sessão do usuário.
- **Utils:** reúnem funções auxiliares, como regras de responsividade.
- **Models:** quando definidos, representam os dados manipulados pela aplicação.

## Tecnologias

- Flutter e Dart para o desenvolvimento multiplataforma;
- Widgets do Flutter para a construção da interface;
- Provider, quando utilizado, para gerenciamento de estado;
- Cliente HTTP para comunicação com a API REST;
- JSON para troca de dados estruturados;
- Flask no backend para disponibilização dos endpoints;
- MySQL no backend para persistência das informações.

## Integração e responsabilidades

O front-end é responsável por apresentar as informações, receber as interações dos usuários, realizar validações iniciais e enviar requisições ao backend. A API é responsável por processar as operações, aplicar as regras de negócio, validar as permissões e persistir os dados no MySQL.

Algumas funcionalidades, como alertas sonoros, notificações push, acionamento efetivo de emergências e envio de e-mails, podem exigir serviços ou mecanismos adicionais além da interface e dos endpoints básicos.

**Observação:** a descrição documenta o propósito e o funcionamento esperado das funcionalidades. A existência de um endpoint na API não garante, por si só, que a respectiva tela, todas as operações ou a integração completa já estejam implementadas no front-end.
