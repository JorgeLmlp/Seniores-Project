class RegistroModel {
  final int? id;
  final DateTime? data;
  final double humor;
  final double dor;
  final double apetite;
  final double mobilidade;
  final int totalIncidentes;
  final String tendencia;
  final String observacoes;
  final String duvidas;

  RegistroModel({
    this.id,
    this.data,
    required this.humor,
    required this.dor,
    required this.apetite,
    required this.mobilidade,
    required this.totalIncidentes,
    required this.tendencia,
    this.observacoes = '',
    this.duvidas = '',
  });

  factory RegistroModel.fromMap(Map<String, dynamic> map) {
    return RegistroModel(
      id: map['id'] as int?,
      data: map['data'] == null
          ? null
          : DateTime.tryParse(map['data'].toString()),
      humor: (map['humor'] as num?)?.toDouble() ?? 0,
      dor: (map['dor'] as num?)?.toDouble() ?? 0,
      apetite: (map['apetite'] as num?)?.toDouble() ?? 0,
      mobilidade: (map['mobilidade'] as num?)?.toDouble() ?? 0,
      totalIncidentes: (map['total_incidentes'] as num?)?.toInt() ?? 0,
      tendencia: (map['tendencia'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      duvidas: (map['duvidas'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'data': (data ?? DateTime.now()).toIso8601String(),
    'humor': humor,
    'dor': dor,
    'apetite': apetite,
    'mobilidade': mobilidade,
    'total_incidentes': totalIncidentes,
    'tendencia': tendencia,
    'observacoes': observacoes,
    'duvidas': duvidas,
  };
}
