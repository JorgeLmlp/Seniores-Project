class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  int? usuarioId;
  String? tipoUsuario;
  String? nomeUsuario;
  String? token;
  int? pacienteSelecionado;
  String? nomePaciente;
  String get escopo => '$tipoUsuario:$usuarioId';

  int get pacienteId {
    if (usuarioId == null ||
        (tipoUsuario != 'paciente' && pacienteSelecionado == null)) {
      throw StateError(
        'Selecione um paciente vinculado na tela Pacientes e vínculos.',
      );
    }
    return tipoUsuario == 'paciente' ? usuarioId! : pacienteSelecionado!;
  }

  void iniciar(Map<String, dynamic> usuario) {
    pacienteSelecionado = null;
    nomePaciente = null;
    token = usuario['token'] as String?;
    usuarioId = usuario['id'] as int?;
    tipoUsuario = usuario['tipo'] as String?;
    nomeUsuario = usuario['name'] as String?;
  }

  void encerrar() {
    token = null;
    pacienteSelecionado = null;
    nomePaciente = null;
    usuarioId = null;
    tipoUsuario = null;
    nomeUsuario = null;
  }
}
