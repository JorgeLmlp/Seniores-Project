# Seniores Front-end

O front-end do Seniores é desenvolvido em Flutter e constitui a camada de interação entre os usuários e o sistema de gerenciamento de cuidados para pessoas idosas. Sua principal responsabilidade é apresentar as informações de maneira organizada, receber os dados inseridos pelos usuários e encaminhar as operações necessárias para a API REST desenvolvida em Flask.

A interface foi concebida para atender às necessidades de pacientes, cuidadores e responsáveis, facilitando o acompanhamento da saúde, a organização de tarefas diárias, o controle de medicamentos e a comunicação entre as pessoas envolvidas na assistência.

Além da apresentação visual, o front-end é responsável pela validação inicial dos formulários, pelo gerenciamento dos estados da interface, pela navegação entre telas e pelo tratamento das respostas recebidas do servidor.

## Funcionalidades

### 1. Login e autenticação

**O que é:** é a funcionalidade responsável por permitir que os usuários acessem o aplicativo por meio de suas credenciais. Ela constitui uma das principais etapas de entrada no sistema, identificando o usuário antes de disponibilizar as áreas que exigem autenticação. a interface apresenta campos para o preenchimento do e-mail e da senha. Antes do envio, o aplicativo pode verificar se os campos foram preenchidos e se os dados apresentam formatos válidos. Em seguida, as informações são encaminhadas à API, que verifica as credenciais. Conforme o resultado da requisição, o aplicativo apresenta uma mensagem de erro ou permite que o usuário prossiga para a tela inicial.

**Importância:** essa funcionalidade organiza o acesso ao sistema, evita que informações sejam apresentadas indiscriminadamente e permite associar as operações realizadas à conta autenticada. A proteção efetiva dos dados também depende das verificações de autorização realizadas no backend.

### 2. Cadastro de usuários

**O que é:** é a funcionalidade que permite criar novas contas para as pessoas que utilizarão o Seniores, reunindo as informações necessárias para identificar cada usuário. O aplicativo apresenta um formulário com campos como nome completo, e-mail, senha, confirmação de senha, CPF, telefone e tipo de usuário. A interface verifica o preenchimento dos campos obrigatórios e pode validar formatos específicos, como e-mail, CPF e telefone. Depois, os dados são enviados à API para que o cadastro seja validado e armazenado.

**Importância:** o cadastro permite que diferentes participantes tenham acesso ao sistema por meio de suas próprias contas. A identificação do tipo de usuário também contribui para organizar a experiência de uso e apoiar a aplicação das permissões correspondentes.

### 3. Perfil do idoso

**O que é:** é a área destinada à apresentação das informações pessoais e dos dados relevantes para o acompanhamento de cada paciente. A interface consulta os dados disponibilizados pela API e apresenta informações como nome, e-mail, telefone, CPF, idade e tipo sanguíneo. Também pode exibir preferências pessoais, como músicas e hobbies. Quando a edição está disponível, o usuário autorizado pode alterar os campos permitidos, enviar as modificações e visualizar os dados atualizados após a resposta do servidor.

**Importância:** o perfil centraliza informações necessárias para a rotina de cuidados e reduz a necessidade de consultar diferentes fontes para localizar os dados básicos do paciente. A apresentação dessas informações deve respeitar as permissões de acesso e os requisitos de privacidade.

### 4. Gerenciamento de medicamentos

**O que é:** é a funcionalidade responsável por apresentar e organizar os medicamentos utilizados pelo idoso, incluindo suas informações de identificação e administração. A tela de medicamentos pode exibir uma lista com nome, dosagem, frequência, horários e descrição de cada item. Por meio de formulários, o usuário autorizado pode cadastrar novos medicamentos, consultar os detalhes de um registro, atualizar suas informações ou solicitar sua exclusão. Essas operações são realizadas por meio de requisições à API, que processa as alterações no banco de dados.

**Importância:** o gerenciamento facilita a visualização dos medicamentos utilizados pelo paciente e ajuda os cuidadores a consultar informações importantes antes da administração. A centralização desses dados também contribui para manter o cadastro atualizado e organizado.

### 5. Alertas sonoros de medicação

**O que é:** é o recurso destinado a auxiliar o usuário a lembrar os horários previstos para a administração dos medicamentos. A interface apresenta os horários cadastrados e as configurações de alerta de cada medicamento. Quando a funcionalidade está implementada, o usuário pode ativar ou desativar o alerta sonoro e selecionar o som disponível. A API armazena as configurações, enquanto o agendamento e a reprodução do áudio dependem do aplicativo ou dos recursos do sistema operacional.

**Importância:** os alertas ajudam a organizar a rotina de administração e diminuem a dependência da memória dos pacientes e cuidadores. Entretanto, a emissão efetiva dos avisos depende de permissões, configurações e mecanismos de execução compatíveis com o dispositivo.

### 6. Confirmação da administração de medicamentos

**O que é:** é a funcionalidade que permite registrar se uma dose prevista foi efetivamente administrada ao paciente. A interface apresenta os medicamentos e suas informações de horário. Quando a confirmação está disponível, o usuário pode indicar que a dose foi administrada e, se necessário, registrar uma observação. O sistema envia os dados à API, que pode armazenar o horário previsto, o momento da administração e a identificação do responsável pela confirmação. Esses registros podem ser consultados posteriormente no histórico.

**Importância:** a confirmação ajuda a diferenciar as doses previstas daquelas que realmente foram administradas. Isso facilita a comunicação entre cuidadores, reduz dúvidas sobre a realização de uma tarefa e contribui para um acompanhamento mais organizado da medicação.

### 7. Agendamento e acompanhamento de consultas

**O que é:** é a funcionalidade que organiza as informações das consultas médicas futuras do paciente. O aplicativo pode apresentar uma lista de consultas com nome do médico, especialidade, local, data e horário. Por meio de formulários, os usuários autorizados podem cadastrar novas consultas ou modificar informações existentes, conforme os recursos implementados. A interface também pode apresentar o estado de cada consulta, como concluída ou histórica, de acordo com os dados retornados pela API.

**Importância:** a organização dessas informações facilita o planejamento dos atendimentos, permite consultar os compromissos futuros e ajuda os responsáveis a manter um histórico dos cuidados médicos. O recurso registra os dados da consulta, mas não significa necessariamente que exista integração com o sistema de agendamento da clínica.

### 8. Prontuário de exames

**O que é:** é a área destinada à organização e à consulta de arquivos relacionados aos exames médicos do paciente. A interface pode apresentar uma lista de documentos disponíveis e suas informações, como nome e tipo de arquivo. Quando o envio está implementado, o usuário pode selecionar uma fotografia ou um documento PDF e encaminhá-lo à API. Para visualizar um documento, o aplicativo pode solicitar o download do arquivo e abri-lo em um visualizador compatível.

**Importância:** o prontuário facilita a localização de exames anteriores e ajuda a manter documentos importantes reunidos em um único sistema. Isso pode tornar a consulta ao histórico mais prática durante o acompanhamento médico, sem substituir os sistemas oficiais de prontuário ou a avaliação profissional.

### 9. Gráficos de evolução da saúde

**O que é:** é o recurso visual que transforma os registros de sinais vitais em representações gráficas, facilitando a comparação das medições ao longo do tempo. O aplicativo utiliza os dados históricos disponibilizados pela API, que podem incluir uma sequência cronológica de datas e séries separadas para cada medida. A interface apresenta os valores em gráficos, permitindo observar como uma determinada medição variou entre diferentes registros. Os gráficos devem utilizar as datas e unidades correspondentes aos dados apresentados.

**Importância:** a visualização gráfica permite compreender tendências de maneira mais intuitiva do que uma lista de números isolados. Ela também facilita a identificação de períodos com mudanças nas medições e pode auxiliar na comunicação de informações aos profissionais responsáveis.

### 10. Registro de incidentes

**O que é:** é a funcionalidade destinada ao registro de ocorrências relevantes na rotina do idoso, como quedas, acidentes e outras intercorrências. A interface apresenta um formulário para registrar o tipo de incidente, a data, o horário, a descrição, a gravidade e as providências adotadas. Depois do preenchimento, os dados são enviados à API e podem ser consultados em uma listagem de ocorrências anteriores.

**Importância:** o registro mantém um histórico das situações que aconteceram durante os cuidados e facilita o acompanhamento das medidas adotadas. Essas informações também podem ajudar os responsáveis a identificar situações recorrentes e a comunicar os acontecimentos aos profissionais de saúde.

### 11. Visualização de relatórios mensais

**O que é:** é a funcionalidade que permite consultar um resumo dos acontecimentos relacionados à rotina de cuidados durante determinado mês. O usuário pode selecionar o período desejado, quando essa opção estiver disponível, e solicitar o relatório à API. O documento gerado pode reunir informações sobre doses administradas, sinais vitais, diário de sintomas, incidentes, consultas, exames, documentos anexados e situação atual de medicamentos e estoque. A interface permite acessar ou visualizar o PDF conforme os recursos implementados.

**Importância:** o relatório reúne diferentes registros em um único documento, reduzindo o trabalho de consultar cada seção separadamente. Ele também facilita a organização do histórico e o compartilhamento de informações com pessoas autorizadas.

### 12. Exportação e compartilhamento de relatórios

**O que é:** é o recurso que permite disponibilizar os relatórios gerados pelo sistema para consulta ou compartilhamento. O front-end solicita à API a geração do relatório mensal e disponibiliza o arquivo PDF ao usuário. Quando o envio por e-mail está integrado à interface, o aplicativo pode oferecer uma ação para solicitar o envio do documento como anexo. O servidor realiza o envio utilizando as configurações de e-mail definidas em seu ambiente.

**Importância:** o compartilhamento facilita o acesso às informações por familiares, cuidadores e profissionais autorizados. A utilização de um documento consolidado também pode simplificar a preparação para consultas e reuniões de acompanhamento.

### 13. Contatos de emergência

**O que é:** é a funcionalidade que apresenta os contatos de pessoas que podem ser importantes durante a rotina de assistência ao idoso. A interface exibe informações como nome, tipo de contato, vínculo com o paciente, telefone, e-mail e especialidade, quando aplicável. Se os recursos estiverem disponíveis, o usuário autorizado também pode cadastrar, atualizar ou excluir contatos por meio de formulários conectados à API.

**Importância:** manter esses dados organizados facilita a localização das pessoas relevantes quando é necessário solicitar informações ou apoio. A interface pode tornar o contato mais prático, mas a realização de chamadas ou mensagens depende das integrações implementadas.

### 14. Diário de sintomas

**O que é:** é a funcionalidade que permite registrar informações sobre o estado físico e o bem-estar do idoso ao longo dos dias. A interface apresenta campos para informar humor, dor, apetite, mobilidade e qualidade do sono. Os níveis numéricos podem variar de 0 a 10, de acordo com o campo, e podem ser complementados por uma descrição, dúvidas ou informações sobre incidentes. Após o preenchimento, os registros são enviados à API e ficam disponíveis para consulta, conforme as permissões de acesso.

**Importância:** o diário ajuda a documentar alterações no bem-estar que poderiam passar despercebidas em uma observação isolada. A consulta ao histórico pode apoiar conversas com profissionais de saúde e facilitar a comunicação entre os responsáveis.

### 15. Escala de turnos dos cuidadores

**O que é:** é a funcionalidade destinada à organização dos horários e dos dias de trabalho dos cuidadores responsáveis pelo atendimento ao paciente. A interface apresenta os turnos cadastrados, incluindo o nome do cuidador, os dias da semana, o horário de início, o horário de término e as observações. Quando a edição está disponível, os usuários autorizados podem registrar ou atualizar a escala, que é armazenada pela API.

**Importância:** a escala ajuda a visualizar a distribuição dos horários de atendimento e a organizar a participação de diferentes cuidadores. Isso favorece a continuidade dos cuidados e facilita a identificação dos responsáveis por cada período.

### 16. Preferências do idoso

**O que é:** é o recurso que apresenta informações sobre os gostos, interesses e preferências pessoais do paciente. A interface consulta o objeto de preferências associado ao perfil do idoso, que pode conter informações como músicas favoritas, hobbies e outras atividades de interesse. Quando a edição está habilitada, o usuário autorizado pode atualizar essas informações, que são encaminhadas à API para armazenamento.

**Importância:** conhecer as preferências do paciente permite organizar atividades mais adequadas aos seus interesses e respeitar sua individualidade. Esse recurso ajuda a considerar aspectos pessoais que vão além das informações clínicas.


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
