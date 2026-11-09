import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService extends ChangeNotifier {
  SessionService._();

  static final SessionService instance = SessionService._();
  static const _sessionKey = 'authenticated_session';

  int? usuarioId;
  String? tipoUsuario;
  String? nomeUsuario;
  String? accessToken;
  int? pacienteSelecionado;
  String? nomePaciente;
  bool _persistente = false;

  bool get autenticado =>
      usuarioId != null &&
      tipoUsuario != null &&
      accessToken != null &&
      accessToken!.isNotEmpty;

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
    _aplicar(usuario);
    _persistente = false;
    notifyListeners();
  }

  Future<void> iniciarLogin(
    Map<String, dynamic> usuario, {
    required bool persistir,
  }) async {
    _aplicar(usuario);
    _persistente = persistir;
    notifyListeners();
    final preferencias = await SharedPreferences.getInstance();
    if (persistir) {
      await preferencias.setString(_sessionKey, jsonEncode(_dadosDaSessao()));
    } else {
      await preferencias.remove(_sessionKey);
    }
  }

  Future<bool> restaurar() async {
    final preferencias = await SharedPreferences.getInstance();
    final salvo = preferencias.getString(_sessionKey);
    if (salvo == null) return false;
    try {
      final dados = jsonDecode(salvo);
      if (dados is! Map<String, dynamic> ||
          dados['id'] is! int ||
          dados['tipo'] is! String ||
          dados['access_token'] is! String ||
          _tokenExpirado(dados['access_token'] as String)) {
        await preferencias.remove(_sessionKey);
        return false;
      }
      _aplicar(dados);
      _persistente = true;
      notifyListeners();
      return true;
    } catch (_) {
      await preferencias.remove(_sessionKey);
      return false;
    }
  }

  Future<void> selecionarPaciente(int id, String nome) async {
    pacienteSelecionado = id;
    nomePaciente = nome;
    notifyListeners();
    await _salvarSePersistente();
  }

  Future<void> atualizarNome(String nome) async {
    nomeUsuario = nome;
    notifyListeners();
    await _salvarSePersistente();
  }

  Future<void> encerrar() async {
    usuarioId = null;
    tipoUsuario = null;
    nomeUsuario = null;
    accessToken = null;
    pacienteSelecionado = null;
    nomePaciente = null;
    _persistente = false;
    notifyListeners();
    await (await SharedPreferences.getInstance()).remove(_sessionKey);
  }

  void _aplicar(Map<String, dynamic> usuario) {
    usuarioId = usuario['id'] as int?;
    tipoUsuario = usuario['tipo'] as String?;
    nomeUsuario = usuario['name'] as String?;
    accessToken = usuario['access_token'] as String?;
    pacienteSelecionado = usuario['paciente_selecionado'] as int?;
    nomePaciente = usuario['nome_paciente'] as String?;
  }

  Map<String, dynamic> _dadosDaSessao() => {
        'id': usuarioId,
        'tipo': tipoUsuario,
        'name': nomeUsuario,
        'access_token': accessToken,
        'paciente_selecionado': pacienteSelecionado,
        'nome_paciente': nomePaciente,
      };

  Future<void> _salvarSePersistente() async {
    if (!_persistente) return;
    await (await SharedPreferences.getInstance()).setString(
      _sessionKey,
      jsonEncode(_dadosDaSessao()),
    );
  }

  bool _tokenExpirado(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );
      final exp = payload is Map<String, dynamic> ? payload['exp'] : null;
      return exp is! int || DateTime.now().millisecondsSinceEpoch >= exp * 1000;
    } catch (_) {
      return true;
    }
  }
}
