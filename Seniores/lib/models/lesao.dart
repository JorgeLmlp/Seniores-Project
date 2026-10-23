class Lesao {
  final int? id;
  final String localizacao;
  final String dataInicio;
  final String descricao;
  final String evolucao;
  final String? fotoNome;
  final List<int>? fotoBytes;

  const Lesao({
    this.id,
    required this.localizacao,
    required this.dataInicio,
    required this.descricao,
    this.evolucao = '',
    this.fotoNome,
    this.fotoBytes,
  });

  factory Lesao.fromMap(Map<String, dynamic> map) {
    return Lesao(
      id: (map['id'] as num?)?.toInt(),
      localizacao: (map['localizacao'] ?? '').toString(),
      dataInicio: (map['data_inicio'] ?? '').toString(),
      descricao: (map['descricao'] ?? '').toString(),
      evolucao: (map['evolucao'] ?? '').toString(),
      fotoNome: map['foto_nome']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'localizacao': localizacao,
    'data_inicio': dataInicio,
    'descricao': descricao,
    'evolucao': evolucao,
  };
}
