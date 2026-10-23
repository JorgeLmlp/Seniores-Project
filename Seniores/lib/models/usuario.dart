class UsuarioVinculado {
  final int id;
  final String nome;
  final String email;
  final String telefone;
  final String cpf;
  final String tipo;

  const UsuarioVinculado({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpf,
    required this.tipo,
  });

  factory UsuarioVinculado.fromMap(Map<String, dynamic> map) {
    return UsuarioVinculado(
      id: (map['id'] as num).toInt(),
      nome: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      telefone: (map['phoneNumber'] ?? '').toString(),
      cpf: (map['cpf'] ?? '').toString(),
      tipo: (map['tipo'] ?? '').toString(),
    );
  }
}
