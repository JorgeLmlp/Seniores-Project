import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:widgets/models/medicamento.dart';
import 'package:widgets/models/sinal_vital.dart';
import 'package:widgets/services/api_service.dart';

void main() {
  test('medicamento serializa somente os campos aceitos pela API', () {
    final medicamento = Medicamento(
      nome: 'Losartana',
      dosagem: '50 mg',
      frequencia: 'diário',
      quantidade: 30,
    );

    expect(medicamento.toJson(), {
      'nome': 'Losartana',
      'dosagem': '50 mg',
      'frequencia': Medicamento.normalizarFrequencia(medicamento.frequencia),
      'horarios': [],
      'alertas': [],
      'quantidade': 30,
    });
  });

  test('API converte a resposta de medicamento para o modelo', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/pacientes/7/medicamentos');
        return http.Response(
          jsonEncode([
            {
              'id': 3,
              'nome': 'Losartana',
              'dosagem': '50 mg',
              'quantidade': 30,
            },
          ]),
          200,
        );
      }),
    );

    final medicamentos = await api.listarMedicamentos(7);

    expect(medicamentos, hasLength(1));
    expect(medicamentos.single.id, 3);
    expect(medicamentos.single.nome, 'Losartana');
    expect(medicamentos.single.quantidade, 30);
  });

  test('sinal vital envia somente as medidas preenchidas', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['pressao_art'], '120/80');
        expect(body.containsKey('glicemia'), isFalse);
        return http.Response(
          jsonEncode({
            'id': 4,
            'data': '2026-10-23T10:00:00',
            'pressao_art': '120/80',
          }),
          201,
        );
      }),
    );

    final salvo = await api.criarSinalVital(
      const SinalVital(pressao: '120/80'),
    );

    expect(salvo.id, 4);
    expect(salvo.pressao, '120/80');
  });

  test('sinal vital valida formato e limites', () {
    expect(
      SinalVitalValidation.validar(const SinalVital(pressao: '120/80')),
      isNull,
    );
    expect(
      SinalVitalValidation.validar(const SinalVital(saturacao: '120')),
      isNotNull,
    );
    expect(
      SinalVitalValidation.validar(const SinalVital(temperatura: 'abc')),
      isNotNull,
    );
  });
}
