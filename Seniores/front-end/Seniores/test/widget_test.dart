import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/models/incidente.dart';
import 'package:widgets/models/medicamento.dart';
import 'package:widgets/models/registroDiario.dart';
import 'package:widgets/services/session_service.dart';

void main() {
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

  test('sessao exige que registros de saude tenham paciente', () {
    SessionService.instance.encerrar();
    expect(() => SessionService.instance.pacienteId, throwsStateError);

    SessionService.instance
        .iniciar({'id': 3, 'tipo': 'paciente', 'name': 'Ana'});
    expect(SessionService.instance.pacienteId, 3);
  });
}
