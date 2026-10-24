class Medicamento {
  final int? id;
  final String nome;
  final String dosagem;
  final String frequencia;
  final List<String> horarios;
  final List<String> alertas;
  final String descricao;
  final String fabricante;
  final String lote;
  final int? quantidade;
  final bool alertaSonoro;
  final String somAlerta;
  final String? fotoUrl;

  Medicamento({
    this.id,
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    this.horarios = const [],
    this.alertas = const [],
    this.descricao = '',
    this.fabricante = '',
    this.lote = '',
    this.quantidade,
    this.alertaSonoro = false,
    this.somAlerta = '',
    this.fotoUrl,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) => Medicamento(
        id: json['id'] as int?,
        nome: json['nome'] as String? ?? '',
        dosagem: json['dosagem'] as String? ?? '',
        frequencia: json['frequencia'] as String? ?? 'diário',
        horarios: (json['horarios'] as List<dynamic>? ?? []).cast<String>(),
        alertas: (json['alertas'] as List<dynamic>? ?? []).cast<String>(),
        descricao: '${json['descricao'] ?? ''}',
        fabricante: '${json['fabricante'] ?? ''}',
        lote: '${json['lote'] ?? ''}',
        quantidade: json['quantidade'] is num ? (json['quantidade'] as num).toInt() : null,
        alertaSonoro: json['alerta_sonoro'] == true,
        somAlerta: '${json['som_alerta'] ?? ''}',
        fotoUrl: json['foto_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'dosagem': dosagem,
        'frequencia': frequencia,
        'horarios': horarios,
        'alertas': alertas,
        'descricao': descricao,
        'fabricante': fabricante,
        'lote': lote,
        'quantidade': quantidade,
        'alerta_sonoro': alertaSonoro,
        'som_alerta': somAlerta,
      };

  String get descricaoSubtitulo {
    if (dosagem.isNotEmpty) {
      return dosagem;
    }
    return "$frequencia - ${horarios.join(', ')}";
  }
}
