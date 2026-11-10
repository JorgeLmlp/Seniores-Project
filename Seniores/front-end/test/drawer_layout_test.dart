import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/services/session_service.dart';
import 'package:widgets/widgets/custom_menu_sanduiche.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(412, 915),
    const Size(800, 360)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('menu $size fonte $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SessionService.instance.iniciar({
          'id': 1,
          'tipo': 'responsavel',
          'name': 'Maria Aparecida de Oliveira Santos',
          'access_token': 'test',
        });
        SessionService.instance.pacienteSelecionado = 2;
        SessionService.instance.nomePaciente =
            'José Antônio de Oliveira Santos';
        final scaffold = GlobalKey<ScaffoldState>();
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(key: scaffold, endDrawer: const MenuSanduiche()),
        ));
        scaffold.currentState!.openEndDrawer();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(Drawer)).width, lessThan(size.width));
        for (final label in [
          'Contatos de emergência',
          'Configurações',
          'Sair da conta'
        ]) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          expect(find.text(label).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.byTooltip('Fechar menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Fechar menu'));
        await tester.pumpAndSettle();
        expect(scaffold.currentState!.isEndDrawerOpen, isFalse);
      });
    }
  }
}
