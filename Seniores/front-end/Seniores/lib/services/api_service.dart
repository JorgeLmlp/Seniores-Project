import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_service.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:5001';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5001'
        : 'http://127.0.0.1:5001';
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      late Future<http.Response> responseFuture;
      final headers = const {'Content-Type': 'application/json'};
      final body = data == null ? null : jsonEncode(data);
      switch (method) {
        case 'GET':
          responseFuture = _client.get(uri, headers: headers);
          break;
        case 'POST':
          responseFuture = _client.post(uri, headers: headers, body: body);
          break;
        case 'PATCH':
          responseFuture = _client.patch(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          responseFuture = _client.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Metodo HTTP nao suportado.');
      }
      final response =
          await responseFuture.timeout(const Duration(seconds: 15));
      final dynamic decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      final message =
          decoded is Map<String, dynamic> ? decoded['erro'] as String? : null;
      throw ApiException(message ?? 'Falha ao comunicar com a API.');
    } on ApiException {
      rethrow;
    } on StateError catch (error) {
      throw ApiException(error.message);
    } on FormatException {
      throw ApiException('A API retornou uma resposta invalida.');
    } on TimeoutException {
      throw ApiException(
        'A API demorou para responder em $_baseUrl.',
      );
    } on http.ClientException {
      throw ApiException(
        'Nao foi possivel conectar a API em $_baseUrl.',
      );
    } catch (_) {
      throw ApiException(
        'Nao foi possivel conectar a API em $_baseUrl. '
        'Verifique o backend e a URL configurada.',
      );
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final result = await _request(
      'POST',
      '/users/login/',
      data: {'email': email, 'senha': senha},
    ) as Map<String, dynamic>;
    SessionService.instance.iniciar(result);
    return result;
  }

  Future<Map<String, dynamic>> criarMedicamento(
      Map<String, dynamic> dados) async {
    final id = SessionService.instance.pacienteId;
    return await _request('POST', '/pacientes/$id/medicamentos', data: dados)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listarMedicamentos() async {
    final id = SessionService.instance.pacienteId;
    final result =
        await _request('GET', '/pacientes/$id/medicamentos') as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> criarDiario(Map<String, dynamic> dados) async {
    final id = SessionService.instance.pacienteId;
    return await _request('POST', '/pacientes/$id/diarios-saude', data: dados)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listarDiarios() async {
    final id = SessionService.instance.pacienteId;
    final result =
        await _request('GET', '/pacientes/$id/diarios-saude') as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> criarRegistro(
    String recurso,
    Map<String, dynamic> dados,
  ) async {
    final id = SessionService.instance.pacienteId;
    return await _request('POST', '/pacientes/$id/$recurso', data: dados)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listarRegistros(String recurso) async {
    final id = SessionService.instance.pacienteId;
    final result =
        await _request('GET', '/pacientes/$id/$recurso') as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<void> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
    required String cpf,
    required String tipo,
  }) async {
    try {
      await _request(
        'POST',
        '/users/',
        data: {
          'nome': nome,
          'email': email,
          'senha': senha,
          'telefone': telefone,
          'cpf': cpf,
          'tipo': tipo,
        },
      );
      return;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException('A API retornou uma resposta invalida.');
    } catch (_) {
      throw ApiException(
          'Nao foi possivel conectar a API. Verifique se o backend esta em execucao e a URL configurada.');
    }
  }
}
