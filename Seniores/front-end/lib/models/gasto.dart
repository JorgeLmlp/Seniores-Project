class Gasto {
  const Gasto({required this.id, required this.categoria, required this.valor,
    required this.tipo, required this.data});

  final String id;
  final String categoria; // Descrição registrada na API
  final double valor;
  final String tipo; // receita ou despesa
  final DateTime data;

  factory Gasto.fromMap(Map<String, dynamic> mapa) {
    // A API devolve registros financeiros simples, mas chamadas antigas
    // podem devolver um objeto com os campos dentro de 'dados'.
    final dados = mapa['dados'] is Map
        ? Map<String, dynamic>.from(mapa['dados'] as Map) : mapa;
    final bruto = dados['valor'];
    return Gasto(
      id: '${mapa['id'] ?? ''}',
      categoria: '${dados['descricao'] ?? dados['categoria'] ?? ''}',
      valor: bruto is num ? bruto.toDouble() : double.tryParse('$bruto') ?? 0,
      tipo: '${dados['tipo'] ?? 'despesa'}',
      data: DateTime.tryParse('${dados['data'] ?? ''}') ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() => {
    'descricao': categoria,
    'valor': valor,
    'tipo': tipo,
    'data': data.toIso8601String(),
  };
}
