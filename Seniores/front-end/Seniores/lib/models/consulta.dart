class Consulta {
  final String id;
  final String nomeDoutor;
  final String especialidade;
  final DateTime dataHora;
  bool historico;
  bool concluida;

  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String estado;
  final String telefone;
  final String whatsapp;
  final String motivo;
  final List<String> alertas;
  final List<String> exames;

  Consulta({
    required this.id,
    required this.nomeDoutor,
    required this.especialidade,
    required this.dataHora,
    this.historico = false,
    this.concluida = false,
    this.cep = '',
    this.logradouro = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.telefone = '',
    this.whatsapp = '',
    this.motivo = '',
    this.alertas = const [],
    this.exames = const [],
  });

  Map<String, dynamic> toJson() => {
        'nomeDoutor': nomeDoutor,
        'especialidade': especialidade,
        'dataHora': dataHora.toIso8601String(),
        'historico': historico,
        'concluida': concluida,
        'cep': cep,
        'logradouro': logradouro,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'telefone': telefone,
        'whatsapp': whatsapp,
        'motivo': motivo,
        'alertas': alertas,
        'exames': exames,
      };

  factory Consulta.fromRegistro(Map<String, dynamic> registro) {
    final json = registro['dados'] as Map<String, dynamic>;
    return Consulta(
      id: registro['id'].toString(),
      nomeDoutor: json['nomeDoutor'] as String? ?? '',
      especialidade: json['especialidade'] as String? ?? '',
      dataHora: DateTime.parse(json['dataHora'] as String),
      historico: json['historico'] as bool? ?? false,
      concluida: json['concluida'] as bool? ?? false,
      cep: json['cep'] as String? ?? '',
      logradouro: json['logradouro'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      motivo: json['motivo'] as String? ?? '',
      alertas: (json['alertas'] as List<dynamic>? ?? []).cast<String>(),
      exames: (json['exames'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
