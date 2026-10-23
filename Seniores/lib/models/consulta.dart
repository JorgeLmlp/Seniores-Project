class Consulta {
  final int? id;
  final String titulo;
  final String especialidade;
  final String profissional;
  final String data;
  final String hora;
  final String local;
  final String telefone;
  final String observacoes;

  const Consulta({
    this.id,
    required this.titulo,
    this.especialidade = '',
    this.profissional = '',
    required this.data,
    this.hora = '',
    this.local = '',
    this.telefone = '',
    this.observacoes = '',
  });

  factory Consulta.fromMap(Map<String, dynamic> map) {
    return Consulta(
      id: map['id'] as int?,
      titulo: (map['titulo'] ?? '').toString(),
      especialidade: (map['especialidade'] ?? '').toString(),
      profissional: (map['profissional'] ?? '').toString(),
      data: (map['data'] ?? '').toString(),
      hora: (map['hora'] ?? '').toString(),
      local: (map['local'] ?? '').toString(),
      telefone: (map['telefone'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'especialidade': especialidade,
    'profissional': profissional,
    'data': data,
    'hora': hora,
    'local': local,
    'telefone': telefone,
    'observacoes': observacoes,
  };
}
