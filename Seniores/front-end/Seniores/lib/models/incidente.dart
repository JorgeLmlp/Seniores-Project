class Incidente {
  final String titulo;
  final String hora;
  final String descricao;
  final String gravidade;

  Incidente({
    required this.titulo,
    required this.hora,
    required this.descricao,
    required this.gravidade,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) => Incidente(
        titulo: json['titulo'] as String? ?? 'Incidente',
        hora: json['hora'] as String? ?? '',
        descricao: json['descricao'] as String? ?? '',
        gravidade: json['gravidade'] as String? ?? '',
      );
}
