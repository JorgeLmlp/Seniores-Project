class Medicamento {
  final int? id;
  final String nome;
  final String dosagem;
  final String frequencia;
  final List<String> horarios;
  final List<String> alertas;

  Medicamento({
    this.id,
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    this.horarios = const [],
    this.alertas = const [],
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) => Medicamento(
        id: json['id'] as int?,
        nome: json['nome'] as String? ?? '',
        dosagem: json['dosagem'] as String? ?? '',
        frequencia: json['frequencia'] as String? ?? 'diário',
        horarios: (json['horarios'] as List<dynamic>? ?? []).cast<String>(),
        alertas: (json['alertas'] as List<dynamic>? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'dosagem': dosagem,
        'frequencia': frequencia,
        'horarios': horarios,
        'alertas': alertas,
      };

  String get descricaoSubtitulo {
    if (dosagem.isNotEmpty) {
      return dosagem;
    }
    return "$frequencia - ${horarios.join(', ')}";
  }
}
