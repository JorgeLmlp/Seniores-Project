# Plano de execução do front-end

Este arquivo acompanha o estado técnico do projeto. Os caminhos são relativos a `Seniores/`.

## Fase 0 — Preparação

- [x] Atualizar o requisito mínimo para Dart 3.12.
- [x] Ocultar da navegação os recursos fora de escopo: Dicionário e Ajuda/Suporte.
- [x] Confirmar que já existem widgets compartilhados de botão, campo, card e lista.
- [ ] Consolidar as duas instalações do Flutter detectadas (`C:\src\flutter` e `C:\Users\Valle\flutter`) em uma única SDK.
- [x] Resolver o conflito `image`/`archive` das dependências; `image 4.10.2`,
  `archive 4.0.9`, `pdf 3.12.0` e `printing 5.14.3` foram fixados e o `pub get`
  resolveu a árvore.
- [ ] Executar `flutter analyze --no-fatal-infos` e corrigir avisos.
- [ ] Executar `flutter test` e `flutter build web`.
- [x] Revisar arquivos com caracteres corrompidos após confirmar a codificação UTF-8 no editor.
- [ ] Padronizar estados de carregamento, vazio, erro/retry e confirmação.
- [x] Remover mocks e dados demonstrativos da produção; mocks restantes estão restritos aos testes HTTP.

### Achados da validação manual

- [x] Confirmado que Dicionário e Ajuda/Suporte não aparecem na navegação.
- [x] Remover o medicamento demonstrativo `Dipirona 500mg`, identificado fixo em `lib/pages/tela_medicamentos.dart`. Confirmado na validação manual.
- [x] Corrigir a abertura das abas Diário, Cuidados e Notificações; as telas e rotas foram implementadas.
- [x] Implementar a navegação equivalente no menu sanduíche para Diário, Cuidados e Notificações.
- [x] Validar o fluxo de saída da conta e novo login.
- [x] Substituir a saudação fixa `Olá, nome!` em `lib/pages/tela_inicio.dart` pelo nome da sessão.
- [x] Substituir a data fixa `13/04` em `lib/pages/tela_inicio.dart` pela data atual.
- [x] Remover ações sem efeito no cadastro de medicamento, diário e menu de configurações.
- [x] Remover fluxo de login demonstrativo do cadastro e callback vazio da lista compartilhada.

## Grupo 1 — Sessão e medicamentos

- [x] Login real contra `POST /users/login/`.
- [x] Persistência opcional da sessão com “Lembrar-me”.
- [x] Logout limpando a sessão persistida.
- [x] Leitura e criação de medicamentos pela API.
- [ ] Validar o grupo com `flutter analyze`, `flutter test`, build Web e fluxo manual.

Observação: o analyzer Dart isolado foi executado e retornou `No issues found!`.
Os comandos Flutter completos ainda aguardam a liberação dos locks das duas SDKs;
há processos Dart ativos associados a elas.

Última verificação técnica: `dart analyze` passou; `python -m compileall -q api`
e a importação da API também passaram. Os gates oficiais `flutter analyze`,
`flutter test` e `flutter build web` continuam pendentes até encerrar os
processos Flutter/Dart ativos.

## Grupo 2 — Conta e documentos legais

- [x] Transformar Termos de Uso e Política de Privacidade em links/telas no cadastro.
- [x] Criar tela de Minha conta com atualização de nome, e-mail, telefone e senha.
- [x] Criar exclusão de conta com confirmação e limpeza da sessão.
- [ ] Validar o grupo com API e fluxo manual.

## Grupo 12 — Perfil e restauração de sessão

- [x] Validar a sessão persistida consultando o usuário na API ao iniciar.
- [x] Adicionar CPF, idade, tipo sanguíneo e preferências à conta.
- [x] Implementar recuperação segura de senha com token assinado, expiração e uso único.
- [ ] Configurar SMTP e validar o recebimento do e-mail de recuperação em ambiente real.
- [ ] Validar manualmente restauração de sessão e edição do perfil.

## Grupo 13 — Cuidadores e destinatários

- [x] Listar cuidador e responsáveis vinculados ao paciente.
- [x] Vincular cuidador e responsável por CPF.
- [x] Editar dados básicos de cuidadores e responsáveis vinculados.
- [x] Desvincular cuidador e responsáveis com confirmação.
- [x] Permitir troca de paciente para o usuário cuidador/responsável.
- [x] Implementar permissões efetivas por perfil: sessão assinada, expiração e escopo por paciente vinculado.
- [x] Validar manualmente os perfis Paciente, Cuidador e Responsável, incluindo escopo de acesso.

Validação técnica de autenticação/permissões: `AUTH_ROLE_SCOPE_OK`; requisição
sem token retorna `401`, usuário vinculado recebe acesso ao paciente correto e
usuário não vinculado recebe `403`. A validação manual com três perfis permanece
concluída com os três perfis.

## Grupo 3 — CRUD de medicamentos

- [x] Persistir frequência, horários e alertas no cadastro do medicamento.
- [x] Abrir tela de detalhes pela lista.
- [x] Editar medicamento pela API (`PATCH /medicamentos/{id}`).
- [x] Excluir medicamento com confirmação pela API (`DELETE /medicamentos/{id}`).
- [ ] Validar cadastro, edição, exclusão e permanência após recarregar a tela.

## Grupo 4 — Consultas e exames

- [x] Criar endpoints persistidos para consultas e exames.
- [x] Criar listagem, cadastro, edição e exclusão na tela de Cuidados.
- [ ] Validar manualmente os CRUDs e confirmar os dados após recarregar a tela.
- [x] Integrar mapas, telefone e WhatsApp com aplicativos externos.
- [x] Integrar upload por seleção e gestão de documentos.
- [x] Integrar captura por câmera para documentos e fotos.
- [ ] Integrar escaneamento especializado de documentos.

Observação: o analyzer Dart isolado, a compilação Python e a importação da API
passaram. `flutter test` e `flutter build web` continuam pendentes enquanto os
processos Dart ativos mantêm locks nas duas instalações do Flutter.

## Grupo 5 — Sinais vitais e evolução

- [x] Validar formato, unidades e limites das medidas no front-end e na API.
- [x] Filtrar o histórico por tipo de medida e período.
- [x] Exibir tendência em gráfico nativo, sem nova dependência.
- [ ] Validar manualmente registro, edição, exclusão, filtros e gráfico.

## Grupo 6 — Estoque

- [x] Criar API persistida para itens de estoque.
- [x] Implementar listagem, cadastro, edição e exclusão.
- [x] Implementar ajuste rápido de quantidade.
- [x] Destacar itens abaixo da quantidade mínima.
- [ ] Validar manualmente CRUD, ajuste rápido e alerta de escassez.

## Grupo 7 — Incidentes

- [x] Criar fluxo independente do diário.
- [x] Persistir tipo, data/hora, descrição, gravidade e providências.
- [x] Implementar histórico, edição, exclusão e marcação como resolvido.
- [ ] Validar manualmente o fluxo completo.

## Grupo 8 — Segurança e emergência

- [x] Criar cadastro, edição e exclusão de contatos de emergência.
- [x] Criar botão de pânico com confirmação.
- [x] Registrar localização e observações no alerta.
- [x] Criar histórico de alertas e resolução.
- [x] Abrir ligação, WhatsApp e SMS com confirmação no aplicativo externo.
- [ ] Validar manualmente contatos, confirmação, alerta e resolução.

## Grupo 9 — Diário de saúde

- [x] Persistir registros diários na API.
- [x] Criar histórico com filtros por período.
- [x] Implementar edição e exclusão com confirmação.
- [ ] Definir se incidentes do diário devem espelhar o módulo independente.
- [ ] Validar manualmente cadastro, histórico, edição, exclusão e filtros.

## Grupo 10 — Gastos

- [x] Criar API persistida e CRUD de gastos.
- [x] Implementar filtros por período, categoria e tipo.
- [x] Recalcular totais e visualização por categoria conforme os filtros.
- [ ] Validar manualmente cadastro, edição, exclusão e filtros.

## Grupo 11 — Central de notificações

- [x] Centralizar alertas de estoque, consultas, exames, incidentes e emergência.
- [x] Persistir estado lida/não lida.
- [x] Redirecionar para o módulo relacionado.
- [x] Implementar estados vazio, carregamento, erro/retry e atualização manual.
- [ ] Validar manualmente leitura, redirecionamento e atualização.

## Próxima sequência

1. Fechar os estados de envio dos comunicados e a exportação/compartilhamento dos relatórios.
2. Concluir os testes manuais pendentes dos módulos já implementados.
3. Implementar a captura/escaneamento especializado de documentos.
4. Padronizar estados de carregamento, vazio, erro/retry e acessibilidade.
5. Executar os gates oficiais do Flutter quando os processos ativos liberarem o SDK.
8. Cuidadores, destinatários e permissões.
9. Rotinas clínicas adicionais.
10. Testes de regressão, acessibilidade e responsividade.

## Backlog funcional completo

### Autenticação e conta

- [x] Recuperação e redefinição de senha integrada à API.
- [x] Persistência opcional da sessão com “Lembrar-me”.
- [x] Validar a sessão restaurada contra a API com token assinado e expiração.
- [x] Termos de Uso e Política de Privacidade como telas acessíveis no cadastro.
- [x] CPF, idade, tipo sanguíneo e preferências no perfil do paciente.
- [x] Atualização e exclusão de conta com confirmação.

### Medicamentos

- [x] Cadastro básico e leitura pela API.
- [x] Descrição, fabricante, lote, quantidade, alerta sonoro e som do alerta.
- [x] Upload de foto do medicamento por seleção de imagem.
- [x] Notificações locais com permissões do sistema operacional em plataformas nativas.
- [x] Reagendamento/cancelamento de alertas ao editar ou excluir medicamentos.
- [x] Confirmação de dose com responsável, horário e observação.
- [x] Edição, detalhes e exclusão de medicamentos.

### Consultas, exames e documentos

- [x] CRUD completo de consultas.
- [x] CRUD completo de exames.
- [x] Abrir localização em aplicativo de mapas.
- [x] Abrir telefone e WhatsApp pelos aplicativos externos.
- [x] Upload de PDF, JPEG, PNG e WebP.
- [x] Seleção de arquivo.
- [x] Captura por câmera.
- [ ] Escaneamento especializado de documentos.
- [x] Listagem, visualização, download e exclusão de documentos.

### Sinais vitais e evolução

- [x] Formulário de pressão, glicemia, temperatura, frequência cardíaca e saturação.
- [x] Histórico com leitura, edição e exclusão.
- [x] Gráficos por período e tipo de medida.
- [x] Validação de unidades, formatos e limites.

### Estoque

- [x] Listagem e CRUD de itens.
- [x] Ajuste rápido de quantidade.
- [x] Quantidade mínima e destaque de estoque baixo.
- [x] Navegação dos alertas para o item correspondente.

### Incidentes

- [x] Fluxo independente de cadastro, detalhes, edição e exclusão.
- [x] Tipo, data/hora, descrição, gravidade e providências.
- [ ] Definir e implementar a regra de espelhamento com o diário.

### Segurança e emergência

- [x] Cadastro, edição e exclusão de contatos de emergência.
- [x] Botão de pânico com confirmação.
- [x] Localização e observações no alerta.
- [x] Histórico e resolução de alertas.
- [x] Ações externas de ligação, WhatsApp e SMS para os contatos, com confirmação no aplicativo externo.

### Cuidadores e destinatários

- [x] Edição e exclusão de cuidadores vinculados.
- [x] CPF no modelo e vinculação de destinatários por CPF.
- [x] Edição e exclusão de destinatários vinculados.
- [x] Troca de paciente vinculado.
- [x] Permissões por perfil: Paciente administra conta/vínculos; Responsável e Cuidador acessam somente pacientes vinculados.

### Comunicados e relatórios

- [x] Edição e exclusão de comunicados.
- [ ] Estados de envio, falha e reenvio persistidos pelo canal de entrega.
- [x] Impedir envio sem destinatário selecionado ou não vinculado.
- [x] Envio do relatório por e-mail via endpoint `/historico/email`.
- [x] Validação de e-mail de destino.
- [x] Estados de geração, progresso e erro na tela.
- [ ] Configurar SMTP e validar entrega real do relatório.
- [x] Geração local, visualização/baixar e compartilhamento do PDF do histórico.

Validação técnica de relatórios: `pdf 3.12.0` + `printing 5.14.3` foram fixados
por compatibilidade com `xml 6.x` exigido pelas notificações locais; analyzer
Dart passou. A validação manual de visualizar/baixar e compartilhar foi
confirmada pelo usuário.

Validação técnica de comunicados: a tela agora exibe estados transitórios de
envio, falha e reenvio, mantendo a mensagem para retry após erro. A confirmação
manual do fluxo foi confirmada pelo usuário. A confirmação persistida do canal
externo permanece pendente até existir um provedor de entrega configurado.

### Diário e rotinas clínicas

- [x] Histórico navegável do diário com filtros por período.
- [x] Edição e exclusão de registros diários.
- [x] Tendências baseadas na comparação com dados reais do histórico.
- [x] Checklist de higiene com API persistida, histórico, edição e exclusão.
- [x] Prontuário de lesões com API persistida, foto, descrição, evolução, edição e exclusão.
- [x] Dietas e restrições alimentares com API persistida, edição, ativação e exclusão.

Validação técnica do checklist de higiene: `HIGIENE_CRUD_OK`, analyzer Dart e
compilação/importação da API passaram. A validação manual da tela permanece
concluída: cadastro, edição, recarregamento e exclusão foram confirmados.

Validação técnica do prontuário de lesões: `LESAO_CRUD_FOTO_OK`, analyzer Dart
e compilação/importação da API passaram. A validação manual da tela permanece
parcialmente concluída: cadastro e foto por seleção foram confirmados; falta
confirmar captura por câmera, edição e exclusão.

Validação técnica de dietas: `DIETA_CRUD_OK`, analyzer Dart e
compilação/importação da API passaram. A validação manual foi concluída pelo
usuário, confirmando o fluxo da tela.

### Gastos e central de notificações

- [x] Exclusão de gastos.
- [x] Filtros por período, categoria e tipo.
- [x] Totais e gráficos dinâmicos conforme filtros.
- [x] Centralizar alertas de medicamentos, consultas, exames, incidentes, estoque e emergência.
- [x] Marcar notificações como lidas/não lidas.
- [x] Redirecionar para o módulo relacionado.
- [x] Empty states, atualização e tratamento de erros.

### Qualidade, acessibilidade e testes

- [ ] Responsividade para celular, tablet, web e desktop.
- [ ] Corrigir overflow, paisagem e navegação por teclado.
- [ ] Contraste, áreas de toque, leitores de tela e escala de fontes.
- [ ] Padronizar carregamento, estados vazios, erros e confirmações.
- [ ] Remover todos os mocks e dados demonstrativos.
- [ ] Corrigir todos os avisos do analyzer.
- [ ] Atualizar e resolver dependências incompatíveis.
- [ ] Testes de widgets e fluxos CRUD.
- [ ] Testes de falhas de API, upload, notificações, relatórios e troca de paciente.

## Fora de escopo

Não adicionar à navegação nem tratar como pendência:

- Turnos de cuidadores;
- Dicionário;
- Ajuda/Suporte.
