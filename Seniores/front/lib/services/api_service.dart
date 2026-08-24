import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  // Pode ser sobrescrita para aparelhos fisicos ou ambientes publicados com:
  // flutter run --dart-define=API_URL=http://192.168.x.x:5000
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;

    // No navegador, localhost aponta para a maquina que executa o Flutter Web.
    if (kIsWeb) return 'http://localhost:5000';

    // 10.0.2.2 e o alias do localhost da maquina anfitria no emulador Android.
    // Nos demais destinos locais, localhost aponta diretamente para a API.
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000'
        : 'http://localhost:5000';
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
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/users/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'senha': senha,
              'telefone': telefone,
              'cpf': cpf,
              'tipo': tipo,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = _decodeBody(response.body);
      if (response.statusCode == 201) return;
      throw ApiException(body['erro'] as String? ?? 'Falha ao cadastrar.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('A API demorou para responder. Verifique se o backend esta em execucao.');
    } on http.ClientException {
      throw ApiException('Nao foi possivel conectar a API em $_baseUrl. Verifique a URL e se o backend esta em execucao.');
    } on FormatException {
      throw ApiException('A API retornou uma resposta invalida.');
    }
  }

  Map<String, dynamic> _decodeBody(String responseBody) {
    if (responseBody.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Resposta JSON deve ser um objeto.');
  }
}
