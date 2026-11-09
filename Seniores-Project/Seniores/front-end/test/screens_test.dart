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
import 'package:widgets/pages/auth/tela_login.dart';
import 'package:widgets/pages/auth/tela_cadastro.dart';
import 'package:widgets/pages/ajuda/tela_ajuda.dart';
import 'package:widgets/pages/dicionario/tela_dicionario.dart';
import 'package:widgets/pages/cuidadores/tela_cuidadores.dart';
import 'package:widgets/pages/cuidadores/tela_listaCuidadores.dart';
import 'package:widgets/pages/cuidadores/tela_cadastroCuidador.dart';
import 'package:widgets/pages/cuidadores/tela_detalhesCuidador.dart';
import 'package:widgets/pages/cuidados/tela_detalhesConsulta.dart';
import 'package:widgets/pages/cuidados/tela_detalhesExames.dart';
import 'package:widgets/pages/medicamentos/tela_detalhesMedicamento.dart';
import 'package:widgets/pages/comunicados/tela_detalhesComunicado.dart';
import 'package:widgets/pages/tela_notificacoes.dart';
import 'package:widgets/pages/tela_vinculos.dart';
import 'package:widgets/pages/tela_permissoes.dart';
import 'package:widgets/models/cuidador.dart';
import 'package:widgets/models/consulta.dart';
import 'package:widgets/models/exame.dart';
import 'package:widgets/models/medicamento.dart';
import 'package:widgets/models/destinatario.dart';

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
    'login': const Login(),
    'cadastro': const Cadastro(),
    'ajuda': const Ajuda(),
    'dicionário': const Dicionario(),
    'cuidadores': const Cuidadores(),
    'lista cuidadores': const ListaCuidadores(),
    'cadastro cuidador': const CadastroCuidador(),
    'detalhes cuidador': DetalheCuidador(
        cuidador: Cuidador(
            nome: 'Ana',
            funcao: 'Cuidadora',
            frequencia: List.filled(7, true),
            horaInicio: '08:00',
            horaFim: '18:00')),
    'detalhes consulta': DetalhesConsulta(
        consulta: Consulta(
            id: '1',
            nomeDoutor: 'Dra. Ana',
            especialidade: 'Clínica',
            dataHora: DateTime(2026, 10, 22))),
    'detalhes exame': DetalhesExame(
        exame: Exame(
            id: '1',
            nomeExame: 'Hemograma',
            local: 'Laboratório',
            dataHora: DateTime(2026, 10, 22),
            concluido: false)),
    'detalhes medicamento': DetalhesMedicamento(
        medicamento: Medicamento(
            id: 1,
            nome: 'Medicamento cadastrado',
            dosagem: '10 mg',
            frequencia: 'diaria',
            horarios: ['08:00'])),
    'detalhes comunicado': DetalhesComunicado(
        destinatario: Destinatario(
            nome: 'Ana', vinculo: 'Familiar', telefone: '11999999999'),
        mensagem: 'Mensagem do paciente'),
    'notificações': const Notificacoes(),
    'vínculos': const Vinculos(),
    'permissões': const PermissoesPaciente(
        pacienteId: 1, pacienteNome: 'Ana', cuidadorId: 2),
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
    for (final escuro in [false, true]) {
      testWidgets('${tela.key} abre a 360px, escuro=$escuro', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await http.runWithClient(() async {
          await tester.pumpWidget(MaterialApp(
              theme: escuro ? ThemeData.dark() : ThemeData.light(),
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
}
