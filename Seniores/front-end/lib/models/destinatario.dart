class Destinatario {
  final String nome;
  final String vinculo;
  final String telefone;
  final String email;
  final String cpf;
  final int? id;

  Destinatario({
    required this.nome,
    required this.vinculo,
    required this.telefone,
    this.email = '',
    this.cpf = '',
    this.id,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'vinculo': vinculo,
        'telefone': telefone,
        'email': email,
        'cpf': cpf,
      };

  factory Destinatario.fromJson(Map<String, dynamic> json) => Destinatario(
        nome: json['nome'] as String? ?? '',
        vinculo: json['vinculo'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        cpf: json['cpf'] as String? ?? '',
        id: json['id'] is int ? json['id'] as int : null,
      );
}
