class Destinatario {
  final String nome;
  final String vinculo;
  final String telefone;

  Destinatario({
    required this.nome,
    required this.vinculo,
    required this.telefone,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'vinculo': vinculo,
        'telefone': telefone,
      };

  factory Destinatario.fromJson(Map<String, dynamic> json) => Destinatario(
        nome: json['nome'] as String? ?? '',
        vinculo: json['vinculo'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
      );
}
