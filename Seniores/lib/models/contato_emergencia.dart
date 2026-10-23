class ContatoEmergencia {
  final int? id;
  final String nome;
  final String telefone;
  final String parentesco;
  final String observacoes;

  const ContatoEmergencia({
    this.id,
    required this.nome,
    required this.telefone,
    this.parentesco = '',
    this.observacoes = '',
  });

  factory ContatoEmergencia.fromMap(Map<String, dynamic> map) {
    return ContatoEmergencia(
      id: map['id'] as int?,
      nome: (map['nome'] ?? '').toString(),
      telefone: (map['telefone'] ?? '').toString(),
      parentesco: (map['parentesco'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'telefone': telefone,
    'parentesco': parentesco,
    'observacoes': observacoes,
  };
}
