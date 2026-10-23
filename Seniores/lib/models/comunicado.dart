class Comunicado {
  final int? id;
  final String titulo;
  final String mensagem;
  final List<int> destinatarios;
  final String status;
  final String? erro;
  final DateTime? criadoEm;

  const Comunicado({
    this.id,
    required this.titulo,
    required this.mensagem,
    required this.destinatarios,
    this.status = 'enviado',
    this.erro,
    this.criadoEm,
  });

  factory Comunicado.fromMap(Map<String, dynamic> map) {
    return Comunicado(
      id: (map['id'] as num?)?.toInt(),
      titulo: (map['titulo'] ?? '').toString(),
      mensagem: (map['mensagem'] ?? '').toString(),
      destinatarios: (map['destinatarios'] as List<dynamic>? ?? [])
          .whereType<num>()
          .map((item) => item.toInt())
          .toList(),
      status: (map['status'] ?? 'enviado').toString(),
      erro: map['erro']?.toString(),
      criadoEm: map['criado_em'] == null
          ? null
          : DateTime.tryParse(map['criado_em'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'mensagem': mensagem,
    'destinatarios': destinatarios,
  };

  Comunicado copyWith({
    int? id,
    String? titulo,
    String? mensagem,
    List<int>? destinatarios,
    String? status,
    String? erro,
    bool limparErro = false,
    DateTime? criadoEm,
  }) {
    return Comunicado(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      destinatarios: destinatarios ?? this.destinatarios,
      status: status ?? this.status,
      erro: limparErro ? null : erro ?? this.erro,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
