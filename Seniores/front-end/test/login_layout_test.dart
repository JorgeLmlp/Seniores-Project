import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/pages/auth/tela_login.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('login largura $width fonte $scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: const Login(),
        ));
        await tester.pumpAndSettle();
        final brand =
            tester.renderObject<RenderParagraph>(find.text('Seniores'));
        expect(
          brand.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 8),
          ),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);

        final enter = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.ensureVisible(enter);
        await tester.tap(enter);
        await tester.pumpAndSettle();
        expect(find.text('Digite seu e-mail.'), findsOneWidget);
        await tester.ensureVisible(find.text('Criar uma conta'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
