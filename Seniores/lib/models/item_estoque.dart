class ItemEstoque {
  final int? id;
  final String nome;
  final String categoria;
  final int quantidade;
  final int quantidadeMinima;
  final String unidade;
  final String observacoes;
  final DateTime? atualizadoEm;

  const ItemEstoque({
    this.id,
    required this.nome,
    this.categoria = '',
    this.quantidade = 0,
    this.quantidadeMinima = 0,
    this.unidade = '',
    this.observacoes = '',
    this.atualizadoEm,
  });

  factory ItemEstoque.fromMap(Map<String, dynamic> map) {
    return ItemEstoque(
      id: map['id'] as int?,
      nome: (map['nome'] ?? '').toString(),
      categoria: (map['categoria'] ?? '').toString(),
      quantidade: (map['quantidade'] as num?)?.toInt() ?? 0,
      quantidadeMinima: (map['quantidade_minima'] as num?)?.toInt() ?? 0,
      unidade: (map['unidade'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      atualizadoEm: map['atualizado_em'] == null
          ? null
          : DateTime.tryParse(map['atualizado_em'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'categoria': categoria,
    'quantidade': quantidade,
    'quantidade_minima': quantidadeMinima,
    'unidade': unidade,
    'observacoes': observacoes,
  };

  bool get estoqueBaixo => quantidade <= quantidadeMinima;
}
