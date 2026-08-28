class Exame {
  final String id;
  final String nomeExame;
  final bool historico;
  final String local;
  final DateTime dataHora;
  bool concluido;
  final String telefone;
  final String whatsapp;
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String estado;

  Exame({
    required this.id,
    required this.nomeExame,
    required this.local,
    required this.dataHora,
    required this.concluido,
    this.historico = false,
    this.telefone = '',
    this.whatsapp = '',
    this.cep = '',
    this.logradouro = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
  });

  Map<String, dynamic> toJson() => {
        'nomeExame': nomeExame,
        'local': local,
        'dataHora': dataHora.toIso8601String(),
        'concluido': concluido,
        'historico': historico,
        'telefone': telefone,
        'whatsapp': whatsapp,
        'cep': cep,
        'logradouro': logradouro,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
      };

  factory Exame.fromRegistro(Map<String, dynamic> registro) {
    final json = registro['dados'] as Map<String, dynamic>;
    return Exame(
      id: registro['id'].toString(),
      nomeExame: json['nomeExame'] as String? ?? '',
      local: json['local'] as String? ?? '',
      dataHora: DateTime.parse(json['dataHora'] as String),
      concluido: json['concluido'] as bool? ?? false,
      historico: json['historico'] as bool? ?? false,
      telefone: json['telefone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      cep: json['cep'] as String? ?? '',
      logradouro: json['logradouro'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
    );
  }
}
