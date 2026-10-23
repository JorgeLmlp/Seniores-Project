class Higiene {
  final int? id;
  final String tipo;
  final String dataHora;
  final Map<String, bool> itens;
  final String observacoes;

  const Higiene({
    this.id,
    required this.tipo,
    required this.dataHora,
    required this.itens,
    this.observacoes = '',
  });

  factory Higiene.fromMap(Map<String, dynamic> map) {
    final dados = map['itens'];
    final itens = <String, bool>{};
    if (dados is Map) {
      for (final entry in dados.entries) {
        if (entry.key is String && entry.value is bool) {
          itens[entry.key as String] = entry.value as bool;
        }
      }
    }
    return Higiene(
      id: (map['id'] as num?)?.toInt(),
      tipo: (map['tipo'] ?? '').toString(),
      dataHora: (map['data_hora'] ?? '').toString(),
      itens: itens,
      observacoes: (map['observacoes'] ?? '').toString(),
    );
  }

  bool get concluida => itens.isNotEmpty && itens.values.every((item) => item);

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'data_hora': dataHora,
    'itens': itens,
    'observacoes': observacoes,
  };
}
