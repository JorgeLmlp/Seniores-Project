class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  int? usuarioId;
  String? tipoUsuario;
  String? nomeUsuario;

  int get pacienteId {
    if (usuarioId == null || tipoUsuario != 'paciente') {
      throw StateError(
        'Entre com uma conta de paciente para registrar dados de saúde.',
      );
    }
    return usuarioId!;
  }

  void iniciar(Map<String, dynamic> usuario) {
    usuarioId = usuario['id'] as int?;
    tipoUsuario = usuario['tipo'] as String?;
    nomeUsuario = usuario['name'] as String?;
  }

  void encerrar() {
    usuarioId = null;
    tipoUsuario = null;
    nomeUsuario = null;
  }
}
