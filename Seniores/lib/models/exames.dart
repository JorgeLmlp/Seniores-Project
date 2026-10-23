class Exame {
  final int? id;
  final String nome;
  final String data;
  final String laboratorio;
  final String local;
  final String observacoes;
  final String documentoUrl;

  const Exame({
    this.id,
    required this.nome,
    required this.data,
    this.laboratorio = '',
    this.local = '',
    this.observacoes = '',
    this.documentoUrl = '',
  });

  factory Exame.fromMap(Map<String, dynamic> map) {
    return Exame(
      id: map['id'] as int?,
      nome: (map['nome'] ?? '').toString(),
      data: (map['data'] ?? '').toString(),
      laboratorio: (map['laboratorio'] ?? '').toString(),
      local: (map['local'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      documentoUrl: (map['documento_url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'data': data,
    'laboratorio': laboratorio,
    'local': local,
    'observacoes': observacoes,
    'documento_url': documentoUrl,
  };
}
