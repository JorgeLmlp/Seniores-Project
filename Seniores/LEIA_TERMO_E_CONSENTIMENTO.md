# Seniores — Termos de Uso e Termo de Consentimento

## Implementação no cadastro

- O texto **Termos de Uso** aparece como link azul e abre sua tela de leitura.
- O texto **Termo de Consentimento** aparece como outro link azul e abre sua própria tela de leitura.
- Há caixas de aceite separadas: o cadastro exige os dois aceites antes do envio.
- As telas exibem os modelos completos enviados em DOCX, com o nome “Seniores” e uma adaptação dos campos descritivos sobre o aplicativo.
- O conteúdo pode ser selecionado e rolado em telas pequenas.

## Arquivos alterados

- `front-end/lib/pages/auth/tela_cadastro.dart`
- `front-end/lib/pages/auth/tela_documentos_legais.dart`
- **Novo:** `front-end/lib/pages/auth/dados_documentos_legais.dart`
- **Novo:** `front-end/test/documentos_legais_cadastro_test.dart`

## Antes de colocar o aplicativo em produção

Os documentos enviados eram **modelos**, não termos jurídicos finais. Foram mantidos os trechos de identificação e contato do controlador/encarregado como **[PENDENTE]**, que precisam ser preenchidos e revisados pela equipe. Além disso, referências a políticas, segurança, compartilhamento e prazo de retenção devem refletir as práticas reais do sistema; a adaptação de interface **não garante conformidade com a LGPD**.

**Importante:** o Flutter exige os dois aceites visualmente, mas esta atualização **não implementa o registro auditável e persistente no backend** da versão e data/hora de consentimento, nem um fluxo de revogação. Isso deve ser definido pela equipe se for exigido na entrega ou publicação.

## Validar no computador

Na pasta `Seniores/front-end`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web
```

Para validar só os testes novos:

```powershell
flutter test test/documentos_legais_cadastro_test.dart
```

O Flutter/Dart não está instalado no ambiente desta edição: o código foi revisado estaticamente, mas os comandos acima ainda precisam ser executados no computador da equipe.
