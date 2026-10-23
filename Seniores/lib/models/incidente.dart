class Incidente {
  final int? id;
  final String tipo;
  final String dataHora;
  final String descricao;
  final String gravidade;
  final String providencias;
  final bool resolvido;

  const Incidente({
    this.id,
    required this.tipo,
    required this.dataHora,
    required this.descricao,
    this.gravidade = 'moderada',
    this.providencias = '',
    this.resolvido = false,
  });

  factory Incidente.fromMap(Map<String, dynamic> map) {
    return Incidente(
      id: map['id'] as int?,
      tipo: (map['tipo'] ?? '').toString(),
      dataHora: (map['data_hora'] ?? '').toString(),
      descricao: (map['descricao'] ?? '').toString(),
      gravidade: (map['gravidade'] ?? 'moderada').toString(),
      providencias: (map['providencias'] ?? '').toString(),
      resolvido: map['resolvido'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'data_hora': dataHora,
    'descricao': descricao,
    'gravidade': gravidade,
    'providencias': providencias,
    'resolvido': resolvido,
  };
}
