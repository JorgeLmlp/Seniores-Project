class AdministracaoMedicamento {
  final int? id;
  final int medicamentoId;
  final String horario;
  final DateTime? administradoEm;
  final int? responsavelId;
  final String observacao;

  const AdministracaoMedicamento({
    this.id,
    required this.medicamentoId,
    required this.horario,
    this.administradoEm,
    this.responsavelId,
    this.observacao = '',
  });

  factory AdministracaoMedicamento.fromMap(Map<String, dynamic> map) {
    return AdministracaoMedicamento(
      id: (map['id'] as num?)?.toInt(),
      medicamentoId: (map['medicamento_id'] as num).toInt(),
      horario: (map['horario'] ?? '').toString(),
      administradoEm: map['administrado_em'] == null
          ? null
          : DateTime.tryParse(map['administrado_em'].toString()),
      responsavelId: (map['responsavel_id'] as num?)?.toInt(),
      observacao: (map['observacao'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'horario': horario,
    if (responsavelId != null) 'responsavel_id': responsavelId,
    if (observacao.trim().isNotEmpty) 'observacao': observacao.trim(),
  };
}
