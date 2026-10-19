class Gasto {
  final String id;
  final String categoria;
  final double valor;
  final String tipo; //Mensal e Anual
  final String corHex;

  Gasto({
    required this.id,
    required this.categoria,
    required this.valor,
    required this.tipo,
    required this.corHex,
  });

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id']?.toString() ?? '',
      categoria: map['categoria'] ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      tipo: map['tipo'] ?? 'Mensal',
      corHex: map['cor'] ?? 'azul',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoria': categoria,
      'valor': valor,
      'tipo': tipo,
      'cor': corHex,
    };
  }
}