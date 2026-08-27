class Medicamento {
  final String nome;
  final String dosagem;
  final String frequencia;
  final List<String> horarios;
  final List<String> alertas;

  Medicamento({
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    this.horarios = const [],
    this.alertas = const [],
  });


  String get descricaoSubtitulo {
    if (dosagem.isNotEmpty) {
      return dosagem;
    }
    return "$frequencia - ${horarios.join(', ')}";
  }
}