import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/pages/auth/tela_cadastro.dart';
import 'package:widgets/pages/auth/dados_documentos_legais.dart';

void main() {
  testWidgets('termos e consentimento abrem documentos diferentes', (tester) async {
    tester.view.physicalSize = const Size(430, 930);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Cadastro()));

    final botaoTermos = find.byKey(const ValueKey('abrir-termos-de-uso'));
    final botaoConsentimento =
        find.byKey(const ValueKey('abrir-termo-consentimento'));
    expect(botaoTermos, findsOneWidget);
    expect(botaoConsentimento, findsOneWidget);

    await tester.ensureVisible(botaoTermos);
    await tester.pumpAndSettle();
    await tester.tap(botaoTermos);
    await tester.pumpAndSettle();
    expect(find.text('Termos de Uso'), findsWidgets);
    expect(blocosTermosDeUso.any((bloco) => bloco.titulo &&
        bloco.texto.startsWith('CLÁUSULA PRIMEIRA')), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(botaoConsentimento);
    await tester.pumpAndSettle();
    await tester.tap(botaoConsentimento);
    await tester.pumpAndSettle();
    expect(find.text('Termo de Consentimento'), findsWidgets);
    expect(blocosTermoConsentimento.any((bloco) => bloco.titulo &&
        bloco.texto.startsWith('CLÁUSULA PRIMEIRA')), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro exibe apenas uma checkbox com dois links', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Cadastro()));

    final aceite = find.byKey(const ValueKey('aceite-termos'));
    final termos = find.byKey(const ValueKey('abrir-termos-de-uso'));
    final consentimento = find.byKey(const ValueKey('abrir-termo-consentimento'));

    expect(find.byType(Checkbox), findsOneWidget);
    expect(aceite, findsOneWidget);
    expect(termos, findsOneWidget);
    expect(consentimento, findsOneWidget);
    expect(tester.widget<Checkbox>(aceite).value, isFalse);

    await tester.ensureVisible(aceite);
    await tester.pumpAndSettle();
    await tester.tap(aceite);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(aceite).value, isTrue);
    expect(tester.takeException(), isNull);
  });
}
