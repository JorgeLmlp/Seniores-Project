import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets/services/local_store.dart';
import 'package:widgets/services/session_service.dart';
import 'package:widgets/services/api_service.dart';
import 'package:widgets/models/consulta.dart';
import 'package:widgets/models/gasto.dart';
import 'package:widgets/models/medicamento.dart';
import 'package:widgets/pages/comunicados/tela_cadastro_destinatario.dart';
import 'package:widgets/pages/medicamentos/tela_detalhes_medicamento.dart';
import 'package:widgets/pages/tela_inicio.dart';
import 'package:widgets/pages/tela_notificacoes.dart';
import 'package:widgets/pages/tela_vinculos.dart';
import 'package:widgets/pages/auth/tela_cadastro.dart';
import 'package:widgets/main.dart';
import 'package:widgets/services/app_settings.dart';
import 'package:widgets/utils/cores.dart';
import 'package:widgets/widgets/custom_menu_sanduiche.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE cache (scope TEXT, key TEXT, value TEXT NOT NULL, PRIMARY KEY(scope,key))',
    );
    LocalStore.instance.useDatabase(db);
    SessionService.instance.iniciar({
      'id': 7,
      'tipo': 'paciente',
      'name': 'Ana',
      'access_token': 'test',
    });
  });
  tearDown(() async {
    await (await LocalStore.instance.database).close();
    await SessionService.instance.encerrar();
  });

  test('consulta envia local e permite exames vazios', () {
    final json = Consulta(
      id: '1',
      nomeDoutor: 'Ana',
      especialidade: 'Clínica',
      dataHora: DateTime(2026, 10, 20, 14, 30),
      logradouro: 'Rua A',
    ).toJson();
    expect(json['local'], 'Rua A');
    expect(json['exames'], isEmpty);
    expect(
      Gasto.fromMap({
        'id': 1,
        'dados': {'categoria': 'Farmácia', 'valor': 12.5, 'tipo': 'Mensal'},
      }).valor,
      12.5,
    );
  });
  test('API preserva erro de validação sem tentar outra rota', () async {
    var chamadas = 0;
    final api = ApiService(
      client: MockClient((request) async {
        chamadas++;
        expect(request.url.path, '/pacientes/7/consultas');
        expect(request.headers['Authorization'], 'Bearer test');
        return http.Response(jsonEncode({'erro': 'Informe o local'}), 400);
      }),
    );
    await expectLater(
      api.criarRegistro('consultas', {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensagem',
          'Informe o local',
        ),
      ),
    );
    expect(chamadas, 1);
  });
  test('API encerra a sessão quando o token é rejeitado', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'erro': 'Token invalido ou expirado.'}),
          401,
        ),
      ),
    );

    await expectLater(
      api.listarMedicamentos(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 401)
            .having((e) => e.message, 'mensagem', contains('sessão expirou')),
      ),
    );
    expect(SessionService.instance.autenticado, isFalse);
  });
  test('SQLite isola contas e limpa somente a conta atual', () async {
    await LocalStore.instance.put('paciente:1', 'draft', {'nome': 'Ana'});
    await LocalStore.instance.put('paciente:2', 'draft', {'nome': 'Bia'});
    await LocalStore.instance.clear('paciente:1');
    expect(await LocalStore.instance.get('paciente:1', 'draft'), isNull);
    expect(
      (await LocalStore.instance.get('paciente:2', 'draft'))['nome'],
      'Bia',
    );
  });
  testWidgets('formulário restaura rascunho após sair e voltar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroDestinatario()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'Contato de teste');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpWidget(const MaterialApp(home: CadastroDestinatario()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    expect(find.text('Contato de teste'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
  });
  testWidgets('cuidador vê convite com responsável e paciente', (tester) async {
    SessionService.instance.iniciar({
      'id': 3,
      'tipo': 'cuidador',
      'name': 'Maria',
      'access_token': 'test',
    });
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Vinculos()));
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.drawer, isNull);
        expect(scaffold.endDrawer, isA<MenuSanduiche>());
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Enviado por João'), findsOneWidget);
        expect(find.text('Aceitar'), findsOneWidget);
        expect(find.text('Recusar'), findsOneWidget);
        expect(find.text('Vincular paciente'), findsNothing);
        tester
            .state<ScaffoldState>(find.byType(Scaffold).first)
            .openEndDrawer();
        await tester.pumpAndSettle();
        expect(
          find.text('Selecione um paciente para liberar as opções de cuidado.'),
          findsOneWidget,
        );
        expect(find.text('Dicionário'), findsNothing);
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (r) async => http.Response(
          jsonEncode(
            r.url.path.endsWith('pacientes')
                ? []
                : [
                    {
                      'id': 1,
                      'status': 'pendente',
                      'paciente': {'nome': 'Ana'},
                      'responsavel': {
                        'nome': 'João',
                        'telefone': '11999999999',
                      },
                      'cuidador': {'nome': 'Maria'},
                    },
                  ],
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
  });
  testWidgets('responsável convida cuidador pelo e-mail cadastrado', (
    tester,
  ) async {
    SessionService.instance.iniciar({
      'id': 2,
      'tipo': 'responsavel',
      'name': 'João',
      'access_token': 'test',
    });
    Map<String, dynamic>? convite;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Vinculos()));
        await tester.pumpAndSettle();
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.drawer, isNull);
        expect(scaffold.endDrawer, isA<MenuSanduiche>());
        expect(find.text('Convidar cuidador por e-mail'), findsOneWidget);

        await tester.tap(find.text('Convidar cuidador por e-mail'));
        await tester.pumpAndSettle();
        expect(find.text('E-mail do cuidador'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField),
          'CUIDADOR@EXEMPLO.COM',
        );
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(convite, {
          'email': 'cuidador@exemplo.com',
          'paciente_id': 7,
        });
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        if (request.method == 'POST') {
          convite = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'id': 4, 'status': 'pendente'}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode(request.url.path.endsWith('pacientes')
              ? [
                  {'id': 7, 'name': 'Ana'},
                ]
              : []),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });
  testWidgets('menu do paciente abre à direita sem desalinhamento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          endDrawer: MenuSanduiche(paginaAtual: 'inicio'),
          body: SizedBox.expand(),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(Drawer)).dx, greaterThan(0));
    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Dicionário'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      300,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'cadastro se adapta a celular estreito e explica o campo inválido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Cadastro()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Cadastrar'),
      400,
      scrollable: find.ancestor(
        of: find.text('Cadastrar'),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();

    expect(find.text('Informe seu nome completo.'), findsAtLeastNWidgets(1));
    expect(find.text('Confira o cadastro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('conclusão de dose retorna os dados para o aviso da tela inicial',
      (
    tester,
  ) async {
    var concluida = false;
    String? observacaoEnviada;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: _AbrirMedicamentoTeste(
              medicamento: Medicamento(
                id: 9,
                nome: 'Losartana',
                dosagem: '50 mg',
                frequencia: 'diária',
                horarios: const ['08:00'],
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir medicamento'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Concluir'));
        await tester.pumpAndSettle();
        // A conclusão exige confirmação explícita; o botão sozinho
        // não deve registrar a administração no servidor.
        expect(find.text('Confirmar dose'), findsOneWidget);
        expect(concluida, isFalse);
        await tester.enterText(find.byType(TextField).last, 'Dose administrada');
        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();
        expect(concluida, isTrue);
        expect(observacaoEnviada, 'Dose administrada');
        expect(find.text('Concluído'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        expect(find.text('Losartana • 08:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        if (request.method == 'PUT') {
          final dados = jsonDecode(request.body) as Map<String, dynamic>;
          concluida = dados['concluida'] == true;
          observacaoEnviada = dados['observacao'] as String?;
          return http.Response(
            jsonEncode({'horario': '08:00', 'concluida': concluida}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({'08:00': concluida}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });
  testWidgets('início mostra dose concluída verde e dose atrasada vermelha', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Home()));
        await tester.pumpAndSettle();

        final concluido = tester.widget<Text>(find.text('Losartana'));
        final atrasado = tester.widget<Text>(find.text('Metformina'));
        expect(concluido.style?.color, Cores.verde);
        expect(atrasado.style?.color, Cores.vermelho);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        dynamic resposta = [];
        if (request.url.path.endsWith('/medicamentos')) {
          resposta = [
            {
              'id': 1,
              'nome': 'Losartana',
              'dosagem': '50 mg',
              'frequencia': 'diária',
              'horarios': ['08:00'],
            },
            {
              'id': 2,
              'nome': 'Metformina',
              'dosagem': '500 mg',
              'frequencia': 'diária',
              'horarios': ['00:00'],
            },
          ];
        } else if (request.url.path.contains('/medicamentos/1/doses/')) {
          resposta = {'08:00': true};
        } else if (request.url.path.contains('/medicamentos/2/doses/')) {
          resposta = {'00:00': false};
        }
        return http.Response(
          jsonEncode(resposta),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });
  testWidgets('responsável recebe medicamento atrasado na tela de avisos', (
    tester,
  ) async {
    SessionService.instance.iniciar({
      'id': 2,
      'tipo': 'responsavel',
      'name': 'João',
      'access_token': 'test',
      'paciente_selecionado': 7,
      'nome_paciente': 'Ana',
    });
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: Notificacoes()));
        await tester.pumpAndSettle();

        expect(find.text('Medicamento atrasado'), findsOneWidget);
        expect(
          find.text('A dose de Losartana das 08:00 ainda não foi concluída.'),
          findsOneWidget,
        );
        expect(
          find.text('Aviso direcionado a você como responsável.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        final resposta = request.url.path.endsWith('/alertas-medicamentos')
            ? [
                {
                  'id': 'dose-1-2026-10-23-08:00',
                  'tipo': 'medicamento_atrasado',
                  'titulo': 'Medicamento atrasado',
                  'mensagem':
                      'A dose de Losartana das 08:00 ainda não foi concluída.',
                  'responsavel_notificado': true,
                },
              ]
            : [];
        return http.Response(
          jsonEncode(resposta),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });
  testWidgets('aplicativo aplica modo escuro e relógio de 24 horas', (
    tester,
  ) async {
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

class _AbrirMedicamentoTeste extends StatefulWidget {
  const _AbrirMedicamentoTeste({required this.medicamento});

  final Medicamento medicamento;

  @override
  State<_AbrirMedicamentoTeste> createState() => _AbrirMedicamentoTesteState();
}

class _AbrirMedicamentoTesteState extends State<_AbrirMedicamentoTeste> {
  Map<String, String>? resultado;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: resultado == null
              ? FilledButton(
                  onPressed: () async {
                    final valor = await Navigator.push<Map<String, String>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalhesMedicamento(
                          medicamento: widget.medicamento,
                        ),
                      ),
                    );
                    if (mounted) setState(() => resultado = valor);
                  },
                  child: const Text('Abrir medicamento'),
                )
              : Text('${resultado!['nome']} • ${resultado!['horario']}'),
        ),
      );
}
