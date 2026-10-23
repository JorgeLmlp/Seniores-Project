import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  int? usuarioId;
  String? tipoUsuario;
  String? nomeUsuario;
  String? emailUsuario;
  String? token;
  int? pacienteSelecionadoId;
  String? pacienteSelecionadoNome;

  bool get isLoggedIn =>
      usuarioId != null && tipoUsuario != null && token != null && token!.isNotEmpty;

  int get pacienteId {
    if (tipoUsuario == 'paciente' && usuarioId != null) {
      return usuarioId!;
    }
    if (pacienteSelecionadoId != null) {
      return pacienteSelecionadoId!;
    }
    throw StateError('Selecione um paciente vinculado para continuar.');
  }

  Future<void> iniciar(
    Map<String, dynamic> usuario, {
    required bool lembrar,
  }) async {
    usuarioId = usuario['id'] as int?;
    tipoUsuario = usuario['tipo']?.toString();
    nomeUsuario = usuario['name']?.toString();
    emailUsuario = usuario['email']?.toString();
    token = usuario['token']?.toString();
    pacienteSelecionadoId = tipoUsuario == 'paciente' ? usuarioId : null;
    pacienteSelecionadoNome = tipoUsuario == 'paciente' ? nomeUsuario : null;

    final prefs = await SharedPreferences.getInstance();
    if (lembrar && isLoggedIn) {
      await prefs.setInt('session.usuario_id', usuarioId!);
      await prefs.setString('session.tipo', tipoUsuario!);
      await prefs.setString('session.nome', nomeUsuario ?? '');
      await prefs.setString('session.email', emailUsuario ?? '');
      await prefs.setString('session.token', token ?? '');
      if (pacienteSelecionadoId != null) {
        await prefs.setInt('session.paciente_id', pacienteSelecionadoId!);
        await prefs.setString(
          'session.paciente_nome',
          pacienteSelecionadoNome ?? '',
        );
      }
    } else {
      await _limparPersistencia(prefs);
    }
  }

  Future<bool> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('session.usuario_id');
    final tipo = prefs.getString('session.tipo');
    if (id == null || tipo == null || tipo.isEmpty) return false;

    usuarioId = id;
    tipoUsuario = tipo;
    nomeUsuario = prefs.getString('session.nome');
    emailUsuario = prefs.getString('session.email');
    token = prefs.getString('session.token');
    if (token == null || token!.isEmpty) return false;
    pacienteSelecionadoId = prefs.getInt('session.paciente_id');
    pacienteSelecionadoNome = prefs.getString('session.paciente_nome');
    if (tipoUsuario == 'paciente') {
      pacienteSelecionadoId = usuarioId;
      pacienteSelecionadoNome = nomeUsuario;
    }
    return true;
  }

  Future<void> encerrar() async {
    usuarioId = null;
    tipoUsuario = null;
    nomeUsuario = null;
    emailUsuario = null;
    token = null;
    pacienteSelecionadoId = null;
    pacienteSelecionadoNome = null;
    final prefs = await SharedPreferences.getInstance();
    await _limparPersistencia(prefs);
  }

  Future<void> selecionarPaciente(int id, String nome) async {
    pacienteSelecionadoId = id;
    pacienteSelecionadoNome = nome;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('session.usuario_id')) {
      await prefs.setInt('session.paciente_id', id);
      await prefs.setString('session.paciente_nome', nome);
    }
  }

  Future<void> atualizarDados({String? nome, String? email}) async {
    nomeUsuario = nome ?? nomeUsuario;
    emailUsuario = email ?? emailUsuario;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('session.usuario_id')) {
      await prefs.setString('session.nome', nomeUsuario ?? '');
      await prefs.setString('session.email', emailUsuario ?? '');
    }
  }

  Future<void> _limparPersistencia(SharedPreferences prefs) async {
    await prefs.remove('session.usuario_id');
    await prefs.remove('session.tipo');
    await prefs.remove('session.nome');
    await prefs.remove('session.email');
    await prefs.remove('session.token');
    await prefs.remove('session.paciente_id');
    await prefs.remove('session.paciente_nome');
  }
}
