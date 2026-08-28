import 'incidente.dart';

class Registro {
  final int? id;
  final String? dataFormatada;
  final int humor;
  final int dor;
  final int apetite;
  final int mobilidade;
  final String? observacoes;
  final List<Incidente>? listaIncidentes;
  final String? tendencia;

  Registro({
    this.id,
    this.dataFormatada,
    this.observacoes,
    this.listaIncidentes,
    this.tendencia,
    required this.humor,
    required this.dor,
    required this.apetite,
    required this.mobilidade,
  });

  int get totalIncidentes => listaIncidentes?.length ?? 0;

  factory Registro.fromApiJson(Map<String, dynamic> json) {
    final data = DateTime.tryParse(json['data_criacao'] as String? ?? '');
    return Registro(
      id: json['id'] as int?,
      dataFormatada: data == null
          ? null
          : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
      humor: json['humor_nivel'] as int? ?? 0,
      dor: json['dor_nivel'] as int? ?? 0,
      apetite: json['apetite_nivel'] as int? ?? 0,
      mobilidade: json['mobilidade_nivel'] as int? ?? 0,
      observacoes: json['descricao'] as String?,
      listaIncidentes: (json['incidentes'] as List<dynamic>? ?? [])
          .map((item) => Incidente.fromJson(item as Map<String, dynamic>))
          .toList(),
      tendencia: 'Estável',
    );
  }

  String _nivelParaStatus(int valor, {bool inverso = false}) {
    final ajustado = inverso ? 10 - valor : valor;
    if (ajustado >= 8) return 'bom';
    if (ajustado >= 5) return 'razoavel';
    if (ajustado >= 3) return 'ruim';
    return 'pessimo';
  }

  Map<String, dynamic> toApiJson({String? duvidas}) => {
        'humor': _nivelParaStatus(humor),
        'dor': _nivelParaStatus(dor, inverso: true),
        'fome': _nivelParaStatus(apetite),
        'mobilidade': _nivelParaStatus(mobilidade),
        'humor_nivel': humor,
        'dor_nivel': dor,
        'apetite_nivel': apetite,
        'mobilidade_nivel': mobilidade,
        'descricao': observacoes,
        'duvidas': duvidas,
        'incidentes': (listaIncidentes ?? [])
            .map((item) => {
                  'titulo': item.titulo,
                  'hora': item.hora,
                  'descricao': item.descricao,
                  'gravidade': item.gravidade,
                })
            .toList(),
      };
}
