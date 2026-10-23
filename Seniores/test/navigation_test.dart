import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:widgets/pages/tela_cuidados.dart';
import 'package:widgets/pages/tela_notificacoes.dart';
import 'package:widgets/widgets/custom_menu.dart';

void main() {
  testWidgets('menu abre Cuidados', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
          bottomNavigationBar: Menu(paginaAtual: 0),
        ),
      ),
    );

    await tester.tap(find.text('Cuidados'));
    await tester.pumpAndSettle();

    expect(find.byType(Cuidados), findsOneWidget);
  });

  testWidgets('menu abre Notificações', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
          bottomNavigationBar: Menu(paginaAtual: 0),
        ),
      ),
    );

    await tester.tap(find.text('Notificações'));
    await tester.pumpAndSettle();

    expect(find.byType(Notificacoes), findsOneWidget);
  });
}
