class DocumentoExame {
  final int id;
  final int exameId;
  final String nome;
  final String mimeType;
  final int tamanho;
  final DateTime? criadoEm;

  const DocumentoExame({
    required this.id,
    required this.exameId,
    required this.nome,
    required this.mimeType,
    required this.tamanho,
    this.criadoEm,
  });

  factory DocumentoExame.fromMap(Map<String, dynamic> map) {
    return DocumentoExame(
      id: (map['id'] as num).toInt(),
      exameId: (map['exame_id'] as num).toInt(),
      nome: (map['nome'] ?? '').toString(),
      mimeType: (map['mime_type'] ?? '').toString(),
      tamanho: (map['tamanho'] as num?)?.toInt() ?? 0,
      criadoEm: map['criado_em'] == null
          ? null
          : DateTime.tryParse(map['criado_em'].toString()),
    );
  }
}
