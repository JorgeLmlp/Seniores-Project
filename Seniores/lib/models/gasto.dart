class Gasto {
  final int? id;
  final String descricao;
  final double valor;
  final String data;
  final String categoria;
  final String tipo;
  final String observacoes;

  const Gasto({
    this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    this.categoria = '',
    this.tipo = '',
    this.observacoes = '',
  });

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int?,
      descricao: (map['descricao'] ?? '').toString(),
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      data: (map['data'] ?? '').toString(),
      categoria: (map['categoria'] ?? '').toString(),
      tipo: (map['tipo'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'descricao': descricao,
    'valor': valor,
    'data': data,
    'categoria': categoria,
    'tipo': tipo,
    'observacoes': observacoes,
  };
}
