import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets/models/incidente.dart';
import 'package:widgets/models/medicamento.dart';
import 'package:widgets/models/registro_diario.dart';
import 'package:widgets/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  String jwtComExpiracao(DateTime data) {
    String parte(Map<String, dynamic> valor) =>
        base64Url.encode(utf8.encode(jsonEncode(valor))).replaceAll('=', '');
    return '${parte({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${parte({'exp': data.millisecondsSinceEpoch ~/ 1000})}.assinatura';
  }

  test('medicamento preserva os campos persistidos pela API', () {
    final medicamento = Medicamento.fromJson({
      'id': 7,
      'nome': 'Losartana',
      'dosagem': '50 mg',
      'frequencia': 'diário',
      'horarios': ['08:00'],
      'alertas': ['Tomar com água'],
    });

    expect(medicamento.id, 7);
    expect(medicamento.toJson()['horarios'], ['08:00']);
  });

  test('diario converte niveis e incidentes para o contrato da API', () {
    final registro = Registro(
      humor: 9,
      dor: 2,
      apetite: 6,
      mobilidade: 4,
      listaIncidentes: [
        Incidente(
          titulo: 'Queda',
          hora: '10:00',
          descricao: 'Sem ferimentos',
          gravidade: 'Média',
        ),
      ],
    );

    final json = registro.toApiJson(duvidas: 'Rever medicação');
    expect(json['humor'], 'bom');
    expect(json['dor'], 'bom');
    expect(json['incidentes'], hasLength(1));
    expect(json['duvidas'], 'Rever medicação');
  });

  test('sessao exige que registros de saude tenham paciente', () async {
    await SessionService.instance.encerrar();
    expect(() => SessionService.instance.pacienteId, throwsStateError);

    SessionService.instance.iniciar({
      'id': 3,
      'tipo': 'paciente',
      'name': 'Ana',
      'access_token': 'test',
    });
    expect(SessionService.instance.pacienteId, 3);
  });

  test('sessao marcada para lembrar e restaurada enquanto token e valido',
      () async {
    final token = jwtComExpiracao(DateTime.now().add(const Duration(hours: 1)));
    SharedPreferences.setMockInitialValues({
      'authenticated_session': jsonEncode({
        'id': 9,
        'tipo': 'paciente',
        'name': 'Maria',
        'access_token': token,
      }),
    });

    expect(await SessionService.instance.restaurar(), isTrue);
    expect(SessionService.instance.autenticado, isTrue);
    expect(SessionService.instance.usuarioId, 9);
  });

  test('sessao expirada nao e restaurada', () async {
    await SessionService.instance.encerrar();
    final token =
        jwtComExpiracao(DateTime.now().subtract(const Duration(minutes: 1)));
    SharedPreferences.setMockInitialValues({
      'authenticated_session': jsonEncode({
        'id': 9,
        'tipo': 'paciente',
        'name': 'Maria',
        'access_token': token,
      }),
    });

    expect(await SessionService.instance.restaurar(), isFalse);
    expect(SessionService.instance.autenticado, isFalse);
  });
}
