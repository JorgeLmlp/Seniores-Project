import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:widgets/services/local_store.dart';
import 'package:widgets/services/session_service.dart';
import 'package:widgets/pages/tela_inicio.dart';
import 'package:widgets/pages/tela_conta.dart';
import 'package:widgets/pages/tela_pdf.dart';
import 'package:widgets/pages/comunicados/tela_comunicados.dart';
import 'package:widgets/pages/comunicados/tela_cadastroDestinatario.dart';
import 'package:widgets/pages/comunicados/tela_envioComunicado.dart';
import 'package:widgets/pages/cuidados/tela_consultas.dart';
import 'package:widgets/pages/cuidados/tela_adicionarConsulta.dart';
import 'package:widgets/pages/cuidados/tela_adicionarExame.dart';
import 'package:widgets/pages/cuidados/tela_exames.dart';
import 'package:widgets/pages/cuidados/tela_cuidados.dart';
import 'package:widgets/pages/medicamentos/tela_medicamentos.dart';
import 'package:widgets/pages/medicamentos/tela_cadastroRemedio.dart';
import 'package:widgets/pages/gastos/tela_gastos.dart';
import 'package:widgets/pages/gastos/tela_novoGasto.dart';
import 'package:widgets/pages/gastos/tela_listaGastos.dart';
import 'package:widgets/pages/registro diario/tela_registroDiario.dart';
import 'package:widgets/pages/registro diario/tela_relatorio.dart';
import 'package:widgets/pages/registro diario/tela_relatorioGrafico.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
        'CREATE TABLE cache (scope TEXT, key TEXT, value TEXT, PRIMARY KEY(scope,key))');
    LocalStore.instance.useDatabase(db);
    SessionService.instance
        .iniciar({'id': 1, 'name': 'Ana', 'tipo': 'paciente', 'token': 'test'});
  });
  tearDown(() async {
    await db.close();
  });
  final telas = <String, Widget>{
    'início': const Home(),
    'conta': const MinhaConta(),
    'configurações': const Configuracoes(),
    'PDF': const RelatoriosPdf(),
    'comunicados': const Destinatarios(),
    'destinatário': const CadastroDestinatario(),
    'envio': const ComunicadosEnvio(destinatariosIniciais: []),
    'consultas': const Consultas(),
    'nova consulta': const AdicionarConsulta(),
    'novo exame': const AdicionarExame(),
    'exames': const Exames(),
    'cuidados': const Cuidados(),
    'medicamentos': const Medicamentos(),
    'novo medicamento': const CadastroRemedio(),
    'gastos': const Gastos(),
    'novo gasto': const NovoGasto(),
    'lista gastos': const ListaGastos(),
    'diário': const RegistroDiario(),
    'relatório': const Relatorio(),
    'gráfico': const RelatorioGrafico(),
  };
  for (final tela in telas.entries) {
    testWidgets('${tela.key} abre em celular no tema escuro', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!),
            home: tela.value));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pumpAndSettle();
        final exception = tester.takeException();
        if (exception != null) debugPrint(exception.toString());
        expect(exception, isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
      },
          () => MockClient((r) async => http.Response(
              jsonEncode(r.url.path == '/minha-conta'
                  ? {
                      'name': 'Ana',
                      'email': 'ana@example.test',
                      'phoneNumber': '11999999999'
                    }
                  : []),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'})));
    });
  }
}
