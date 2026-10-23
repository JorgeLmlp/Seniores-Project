class Notificacao {
  final int id;
  final String tipo;
  final int? referenciaId;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? criadoEm;

  const Notificacao({
    required this.id,
    required this.tipo,
    this.referenciaId,
    required this.titulo,
    required this.mensagem,
    this.lida = false,
    this.criadoEm,
  });

  factory Notificacao.fromMap(Map<String, dynamic> map) {
    return Notificacao(
      id: (map['id'] as num).toInt(),
      tipo: (map['tipo'] ?? '').toString(),
      referenciaId: (map['referencia_id'] as num?)?.toInt(),
      titulo: (map['titulo'] ?? '').toString(),
      mensagem: (map['mensagem'] ?? '').toString(),
      lida: map['lida'] as bool? ?? false,
      criadoEm: map['criado_em'] == null
          ? null
          : DateTime.tryParse(map['criado_em'].toString()),
    );
  }
}
