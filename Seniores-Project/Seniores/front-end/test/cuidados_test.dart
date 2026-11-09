import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:widgets/models/recurso_cuidado.dart';
import 'package:widgets/pages/cuidados/formulario_cuidado.dart';
import 'package:widgets/pages/cuidados/tela_registros_cuidado.dart';
import 'package:widgets/pages/cuidados/tela_evolucao_vital.dart';
import 'package:widgets/services/api_service.dart';
import 'package:widgets/services/session_service.dart';
import 'package:widgets/pages/tela_conta.dart';
import 'package:widgets/pages/tela_pdf.dart';

Widget app(Widget tela, {bool escuro = false}) => MaterialApp(
      theme: escuro ? ThemeData.dark() : ThemeData.light(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: tela,
    );
http.Response json(dynamic value, [int status = 200]) =>
    http.Response(jsonEncode(value), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  setUp(() => SessionService.instance.iniciar(
      {'id': 7, 'tipo': 'paciente', 'name': 'Maria', 'token': 'test'}));
  tearDown(() => SessionService.instance.encerrar());

  test('anexo usa multipart com autenticação e download preserva bytes', () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70, 45]);
    final api = ApiService(client: MockClient((r) async {
      expect(r.headers['Authorization'], 'Bearer test');
      if (r.method == 'POST') {
        expect(r.url.path, '/pacientes/7/exames-documentos');
        expect(r.headers['content-type'], contains('multipart/form-data; boundary='));
        expect(r.body, contains('filename="exame.pdf"'));
        expect(r.body, contains('application/pdf'));
        expect(r.body, contains('Hemograma'));
        return json({'id': 1}, 201);
      }
      expect(r.url.path, '/exames-documentos/1/arquivo');
      return http.Response.bytes(bytes, 200);
    }));
    await api.anexarExame(7, {'nome': 'Hemograma'}, bytes, 'exame.pdf', 'application/pdf');
    expect(await api.baixarArquivo('/exames-documentos/1/arquivo'), bytes);
  });

  testWidgets('perfil salva idade e preferências na rota da própria conta', (tester) async {
    Map<String, dynamic>? salvo;
    await http.runWithClient(() async {
      await tester.pumpWidget(app(const MinhaConta()));
      await tester.pumpAndSettle();
      final idade = find.widgetWithText(TextField, 'Idade');
      await tester.ensureVisible(idade);
      await tester.enterText(idade, '78');
      final hobbies = find.widgetWithText(TextField, 'Hobbies');
      await tester.ensureVisible(hobbies);
      await tester.enterText(hobbies, 'xadrez, leitura');
      await tester.ensureVisible(find.text('Salvar alterações'));
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();
      expect(salvo?['idade'], 78);
      expect(salvo?['preferencias']['hobbies'], ['xadrez', 'leitura']);
      expect(salvo?['preferencias']['outro'], 'preservado');
    }, () => MockClient((r) async {
      if (r.method == 'PATCH') {
        expect(r.url.path, '/users/paciente/7/');
        salvo = jsonDecode(r.body) as Map<String, dynamic>;
      }
      return json({'name': 'Maria', 'email': 'maria@example.test', 'phoneNumber': '11999999999',
          'preferencias': {'outro': 'preservado'}});
    }));
  });

  testWidgets('envio do relatório valida e-mail e mostra erro do servidor', (tester) async {
    var chamadas = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(app(const RelatoriosPdf()));
      final botao = find.text('Enviar relatório por e-mail');
      await tester.ensureVisible(botao);
      await tester.tap(botao); await tester.pumpAndSettle();
      expect(chamadas, 0);
      await tester.enterText(find.byType(TextFormField), 'familia@example.test');
      await tester.ensureVisible(botao);
      await tester.tap(botao); await tester.pumpAndSettle();
      expect(chamadas, 1);
      expect(find.text('SMTP não configurado'), findsOneWidget);
    }, () => MockClient((r) async {
      chamadas++;
      expect(r.url.path, '/pacientes/7/historico/email');
      expect(jsonDecode(r.body)['email'], 'familia@example.test');
      return json({'erro': 'SMTP não configurado'}, 503);
    }));
  });

  for (final recurso in recursosCuidado) {
    for (final escuro in [false, true]) {
      testWidgets(
          '${recurso.titulo}: lista e formulário a 320px, escuro=$escuro',
          (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ApiService(client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer test');
          return json(r.url.path == '/minha-conta/pacientes'
              ? [
                  {'id': 7, 'pode_escrever': true}
                ]
              : []);
        }));
        await tester.pumpWidget(
            app(RegistrosCuidado(recurso: recurso, api: api), escuro: escuro));
        await tester.pumpAndSettle();
        expect(find.text('Nenhum registro cadastrado.'), findsOneWidget);
        await tester.tap(find.text('Adicionar'));
        await tester.pumpAndSettle();
        expect(find.byType(FormularioCuidado), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Salvar registro'), 250,
            scrollable: find.byType(Scrollable).last);
        await tester.tap(find.text('Salvar registro'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('somente leitura oculta inclusão, edição e exclusão',
      (tester) async {
    final api = ApiService(
        client:
            MockClient((r) async => json(r.url.path == '/minha-conta/pacientes'
                ? [
                    {'id': 7, 'pode_escrever': false}
                  ]
                : [
                    {
                      'id': 9,
                      'nome': 'Fraldas',
                      'quantidade': 2,
                      'quantidade_minima': 5,
                      'estoque_baixo': true
                    }
                  ])));
    await tester.pumpWidget(
        app(RegistrosCuidado(recurso: recursosCuidado[1], api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Estoque baixo'), findsOneWidget);
    expect(find.textContaining('Somente leitura.'), findsOneWidget);
  });

  testWidgets(
      'erro de leitura não é mostrado como lista vazia e permite tentar novamente',
      (tester) async {
    var falha = true;
    final api = ApiService(
        client: MockClient((r) async => r.url.path == '/minha-conta/pacientes'
            ? json([
                {'id': 7, 'pode_escrever': true}
              ])
            : falha
                ? json({'erro': 'Serviço indisponível'}, 503)
                : json([])));
    await tester.pumpWidget(
        app(RegistrosCuidado(recurso: recursosCuidado[1], api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Serviço indisponível'), findsOneWidget);
    expect(find.text('Nenhum registro cadastrado.'), findsNothing);
    falha = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum registro cadastrado.'), findsOneWidget);
  });

  testWidgets('estoque cria com inteiros, edita e exclui após confirmação',
      (tester) async {
    final registros = <Map<String, dynamic>>[];
    final mutacoes = <String>[];
    final api = ApiService(client: MockClient((r) async {
      if (r.url.path == '/minha-conta/pacientes') {
        return json([
          {'id': 7, 'pode_escrever': true}
        ]);
      }
      if (r.method == 'GET') return json(registros);
      mutacoes.add(r.method);
      if (r.method == 'DELETE') {
        registros.clear();
        return http.Response('', 204);
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['quantidade'], isA<int>());
      if (r.method == 'POST') {
        expect(r.url.path, '/pacientes/7/estoque');
        registros.add({'id': 9, ...body});
      } else {
        expect(r.url.path, '/estoque/9');
        registros[0].addAll(body);
      }
      return json(registros.first, r.method == 'POST' ? 201 : 200);
    }));
    await tester.pumpWidget(
        app(RegistrosCuidado(recurso: recursosCuidado[1], api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Fraldas');
    await tester.enterText(find.byType(TextFormField).at(1), '-1');
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();
    expect(mutacoes, isEmpty);
    await tester.enterText(find.byType(TextFormField).at(1), '12');
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();
    expect(find.text('Fraldas'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '8');
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(mutacoes, ['POST', 'PATCH']);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(mutacoes, ['POST', 'PATCH', 'DELETE']);
    expect(find.text('Nenhum registro cadastrado.'), findsOneWidget);
  });

  testWidgets('dieta converte listas e mantém formulário em erro de gravação',
      (tester) async {
    Map? enviado;
    final api = ApiService(client: MockClient((r) async {
      enviado = jsonDecode(r.body) as Map;
      return json(
          {'erro': 'Permissão de somente leitura para este paciente.'}, 403);
    }));
    await tester.pumpWidget(app(FormularioCuidado(
        recurso: recursosCuidado[3], pacienteId: 7, api: api)));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Dieta registrada');
    await tester.enterText(find.byType(TextFormField).at(1), 'sal, açúcar, ');
    await tester.tap(find.text('Salvar registro'));
    await tester.pumpAndSettle();
    expect(enviado?['restricoes'], ['sal', 'açúcar']);
    expect(enviado?['alergias'], []);
    expect(find.text('Permissão de somente leitura para este paciente.'),
        findsOneWidget);
    expect(find.text('Dieta registrada'), findsOneWidget);
  });

  testWidgets('evolução lida com medição única e campos ausentes',
      (tester) async {
    final api = ApiService(
        client: MockClient((r) async => json({
              'labels': ['2026-10-22T08:00:00'],
              'series': {
                'temperatura': ['36.5']
              }
            })));
    await tester.pumpWidget(app(EvolucaoVital(api: api, pacienteId: 7)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(ListTile, '36.5'), findsOneWidget);
  });
}
