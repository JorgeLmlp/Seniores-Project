class Dieta {
  final int? id;
  final String tipo;
  final String dataInicio;
  final String descricao;
  final String restricoes;
  final String observacoes;
  final bool ativa;

  const Dieta({
    this.id,
    required this.tipo,
    required this.dataInicio,
    required this.descricao,
    this.restricoes = '',
    this.observacoes = '',
    this.ativa = true,
  });

  factory Dieta.fromMap(Map<String, dynamic> map) {
    return Dieta(
      id: (map['id'] as num?)?.toInt(),
      tipo: (map['tipo'] ?? '').toString(),
      dataInicio: (map['data_inicio'] ?? '').toString(),
      descricao: (map['descricao'] ?? '').toString(),
      restricoes: (map['restricoes'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      ativa: map['ativa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'data_inicio': dataInicio,
    'descricao': descricao,
    'restricoes': restricoes,
    'observacoes': observacoes,
    'ativa': ativa,
  };
}
