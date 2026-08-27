import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

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
            Uri.parse('$baseUrl/users/'),
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
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) return;
      throw ApiException(body['erro'] as String? ?? 'Falha ao cadastrar.');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException('A API retornou uma resposta invalida.');
    } catch (_) {
      throw ApiException('Nao foi possivel conectar a API. Verifique se o backend esta em execucao e a URL configurada.');
    }
  }
}
