import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:widgets/services/local_store.dart';
import 'package:widgets/services/session_service.dart';
import 'package:widgets/services/api_service.dart';
import 'package:widgets/models/consulta.dart';
import 'package:widgets/models/gasto.dart';
import 'package:widgets/pages/comunicados/tela_cadastroDestinatario.dart';
import 'package:widgets/pages/tela_vinculos.dart';
import 'package:widgets/main.dart';
import 'package:widgets/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
        'CREATE TABLE cache (scope TEXT, key TEXT, value TEXT NOT NULL, PRIMARY KEY(scope,key))');
    LocalStore.instance.useDatabase(db);
    SessionService.instance
        .iniciar({'id': 7, 'tipo': 'paciente', 'name': 'Ana', 'token': 'test'});
  });
  tearDown(() async {
    await (await LocalStore.instance.database).close();
    SessionService.instance.encerrar();
  });

  test('consulta envia local e permite exames vazios', () {
    final json = Consulta(
            id: '1',
            nomeDoutor: 'Ana',
            especialidade: 'Clínica',
            dataHora: DateTime(2026, 10, 20, 14, 30),
            logradouro: 'Rua A')
        .toJson();
    expect(json['local'], 'Rua A');
    expect(json['exames'], isEmpty);
    expect(
        Gasto.fromMap({
          'id': 1,
          'dados': {'categoria': 'Farmácia', 'valor': 12.5, 'tipo': 'Mensal'}
        }).valor,
        12.5);
  });
  test('API preserva erro de validação sem tentar outra rota', () async {
    var chamadas = 0;
    final api = ApiService(client: MockClient((request) async {
      chamadas++;
      expect(request.url.path, '/pacientes/7/consultas');
      expect(request.headers['Authorization'], 'Bearer test');
      return http.Response(jsonEncode({'erro': 'Informe o local'}), 400);
    }));
    await expectLater(
        api.criarRegistro('consultas', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'mensagem', 'Informe o local')));
    expect(chamadas, 1);
  });
  test('SQLite isola contas e limpa somente a conta atual', () async {
    await LocalStore.instance.put('paciente:1', 'draft', {'nome': 'Ana'});
    await LocalStore.instance.put('paciente:2', 'draft', {'nome': 'Bia'});
    await LocalStore.instance.clear('paciente:1');
    expect(await LocalStore.instance.get('paciente:1', 'draft'), isNull);
    expect(
        (await LocalStore.instance.get('paciente:2', 'draft'))['nome'], 'Bia');
  });
  testWidgets('formulário restaura rascunho após sair e voltar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroDestinatario()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'Contato de teste');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpWidget(const MaterialApp(home: CadastroDestinatario()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump();
    expect(find.text('Contato de teste'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
  });
  testWidgets('cuidador vê convite com responsável e paciente', (tester) async {
    SessionService.instance.iniciar(
        {'id': 3, 'tipo': 'cuidador', 'name': 'Maria', 'token': 'test'});
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Vinculos()));
      await tester.pumpAndSettle();
      expect(find.text('Paciente: Ana'), findsOneWidget);
      expect(find.text('Responsável: João'), findsOneWidget);
      expect(find.text('Aceitar'), findsOneWidget);
      expect(find.text('Recusar'), findsOneWidget);
      expect(find.text('Vincular paciente por CPF'), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async => http.Response(
            jsonEncode(r.url.path.endsWith('pacientes')
                ? []
                : [
                    {
                      'id': 1,
                      'status': 'pendente',
                      'paciente': {'nome': 'Ana'},
                      'responsavel': {
                        'nome': 'João',
                        'telefone': '11999999999'
                      },
                      'cuidador': {'nome': 'Maria'}
                    }
                  ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'})));
  });
  testWidgets('aplicativo aplica modo escuro e relógio de 24 horas',
      (tester) async {
    AppSettings.instance.value = ThemeMode.dark;
    await tester.pumpWidget(const SenioresApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MediaQuery.of(context).alwaysUse24HourFormat, isTrue);
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
    expect(tester.takeException(), isNull);
    AppSettings.instance.value = ThemeMode.system;
  });
}
