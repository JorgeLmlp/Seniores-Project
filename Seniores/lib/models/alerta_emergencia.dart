class AlertaEmergencia {
  final int? id;
  final DateTime? dataHora;
  final String localizacao;
  final String observacoes;
  final String status;

  const AlertaEmergencia({
    this.id,
    this.dataHora,
    this.localizacao = '',
    this.observacoes = '',
    this.status = 'aberto',
  });

  factory AlertaEmergencia.fromMap(Map<String, dynamic> map) {
    return AlertaEmergencia(
      id: map['id'] as int?,
      dataHora: map['data_hora'] == null
          ? null
          : DateTime.tryParse(map['data_hora'].toString()),
      localizacao: (map['localizacao'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      status: (map['status'] ?? 'aberto').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'localizacao': localizacao,
    'observacoes': observacoes,
  };
}
