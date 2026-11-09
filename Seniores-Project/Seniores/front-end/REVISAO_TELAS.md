# Implementação e revisão das telas — 22/10/2026

## Funcionalidades adicionadas

As telas abaixo são acessíveis pela seção **Cuidados** e pelo menu lateral.
As listas usam o paciente selecionado, oferecem busca e atualização, distinguem
erro de lista vazia e consultam `pode_escrever` em `/minha-conta/pacientes`.
As operações de escrita continuam sujeitas à autorização da API.

| Tela | Recurso da API | Operações |
| --- | --- | --- |
| Sinais vitais | `sinais-vitais` | Listar, cadastrar, editar, excluir e consultar evolução |
| Estoque | `estoque` | CRUD e indicação de estoque baixo |
| Higiene | `checklists-higiene` | CRUD, concluir e reabrir tarefa |
| Dieta e restrições | `dietas-restricoes` | CRUD, restrições e alergias como listas |
| Lesões | `lesoes` | CRUD, anexar/substituir/remover foto e visualizar |
| Incidentes | `incidentes` | CRUD com data, gravidade e providências |
| Contatos de emergência | `contatos-emergencia` | CRUD de familiares e médicos |
| Pedidos de ajuda | `alertas-panico` | CRUD e conclusão de atendimento |
| Turnos de cuidado | `turnos-cuidadores` | CRUD com dias da semana e horários |
| Documentos de exames | `exames-documentos` | Listar, anexar, visualizar e excluir |
| Receitas e despesas | `registros-financeiros` | CRUD com valor, tipo e data |

Também foram acrescentados:

- Idade, tipo sanguíneo, músicas e hobbies na conta do paciente, usando a rota
  de atualização da própria conta. O controle de acesso existente não permite
  que cuidadores editem o perfil de outra conta por essa rota.
- Envio de relatório mensal por e-mail na tela de relatórios. A interface
  apresenta o erro retornado quando SMTP não está configurado; os testes não
  enviam mensagens reais.
- Agenda de cuidadores alimentada pelo recurso `cuidadores`, com datas da
  semana atual, substituindo nomes e horários fixos. A agenda antiga e os
  novos turnos são recursos distintos na API e têm acessos separados.
- Acesso aos documentos pelo cadastro de exame, substituindo botões sem ação.

Uploads de exames aceitam PDF, JPEG, PNG e WebP até 10 MB. Fotografias de lesões
aceitam JPEG, PNG, WebP e GIF até 5 MB. Downloads e uploads usam a sessão
autenticada. PDFs e imagens podem ser visualizados dentro do aplicativo.

## Revisão de layout

Foram corrigidos estouros de largura em cabeçalhos, textos de login,
seletores, cadastro de cuidadores, indicadores do diário e páginas de
comunicados, consultas e medicamentos. O cartão compartilhado agora contém
um `Material` para permitir que os efeitos de toque de `ListTile` apareçam.
Detalhes do comunicado podem rolar quando o conteúdo não cabe na tela.

Os testes de renderização cobrem as 35 páginas existentes nos temas claro e
escuro em largura de 360 px. As 11 listas novas e seus formulários são
verificados em 320 px nos dois temas. Há testes de CRUD, somente leitura,
falha e nova tentativa, validação, conversão de listas, evolução com medição
única, multipart autenticado, edição de perfil e falha no envio de relatório.
Esses testes verificam layout e comportamento com HTTP simulado; não são uma
comparação de pixels com o Figma nem um teste ponta a ponta em banco real.

## Comparação com o Figma pendente

Referência solicitada:
https://www.figma.com/design/UT5l2awAf38OePvDTgvEQ0/Untitled?node-id=0-1

O arquivo não pôde ser aberto pela ferramenta de navegação e não havia uma
integração Figma conectada nesta sessão. A implementação segue os componentes
e a paleta existentes no repositório, sem afirmar conformidade com o arquivo.
Ainda é necessário comparar todas as páginas com os frames: composição,
tipografia, cores, ícones, espaçamentos e estados. A fonte Inter é citada nos
componentes antigos, mas não está incluída como asset no `pubspec.yaml`; sua
correspondência com a referência também precisa ser confirmada.

## Executar a verificação

Resultado nesta sessão: 113 casos distintos aprovados (suíte de 110 casos e
execução focada com os três testes acrescentados), build web release gerado e
análise sem erros ou warnings. Permanecem apontamentos informativos de estilo.

```powershell
flutter pub get
flutter test
flutter analyze --no-fatal-infos
flutter build web --release
```

O seletor nativo de arquivos requer recompilar o aplicativo depois de atualizar
as dependências. A execução dos seletores nativos Android, iOS, macOS, Linux e
Windows não foi validada em dispositivos nesta sessão.
