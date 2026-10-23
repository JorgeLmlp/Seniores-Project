class Medicamento {
  final int? id;
  final String nome;
  final String dosagem;
  final String frequencia;
  final List<String> horarios;
  final List<String> alertas;
  final String? descricao;
  final String? fabricante;
  final String? lote;
  final int? quantidade;
  final bool alertaSonoro;
  final String? somAlerta;
  final String? fotoNome;
  final List<int>? fotoBytes;

  Medicamento({
    this.id,
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    this.horarios = const [],
    this.alertas = const [],
    this.descricao,
    this.fabricante,
    this.lote,
    this.quantidade,
    this.alertaSonoro = false,
    this.somAlerta,
    this.fotoNome,
    this.fotoBytes,
  });

  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'] as int?,
      nome: (map['nome'] ?? '').toString(),
      dosagem: (map['dosagem'] ?? '').toString(),
      frequencia: normalizarFrequencia(map['frequencia']),
      horarios: (map['horarios'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      alertas: (map['alertas'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      descricao: map['descricao']?.toString(),
      fabricante: map['fabricante']?.toString(),
      lote: map['lote']?.toString(),
      quantidade: map['quantidade'] as int?,
      alertaSonoro: map['alerta_sonoro'] as bool? ?? false,
      somAlerta: map['som_alerta']?.toString(),
      fotoNome: map['foto_nome']?.toString(),
    );
  }

  static String normalizarFrequencia(Object? valor) {
    final frequencia = valor?.toString().trim().toLowerCase() ?? '';
    if (frequencia == 'semanal' || frequencia == 'semanalmente') {
      return 'semanal';
    }
    if (frequencia == 'mensal' || frequencia == 'mensalmente') {
      return 'mensal';
    }
    return 'diario';
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'dosagem': dosagem,
      'frequencia': normalizarFrequencia(frequencia),
      'horarios': horarios,
      'alertas': alertas,
      'descricao': descricao,
      'fabricante': fabricante,
      'lote': lote,
      'quantidade': quantidade,
      'alerta_sonoro': alertaSonoro,
      'som_alerta': somAlerta,
      'foto_nome': fotoNome,
    }..removeWhere((_, value) => value == null || value == '');
  }

  String get descricaoSubtitulo {
    if (dosagem.isNotEmpty) {
      return dosagem;
    }
    return "$frequencia - ${horarios.join(', ')}";
  }
}
