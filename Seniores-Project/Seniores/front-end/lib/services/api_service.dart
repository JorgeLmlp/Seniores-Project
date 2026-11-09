import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'session_service.dart';
import 'local_store.dart';

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
      final headers = {
        'Content-Type': 'application/json',
        if (SessionService.instance.token != null)
          'Authorization': 'Bearer ${SessionService.instance.token}'
      };
      final body = data == null ? null : jsonEncode(data);
      switch (method) {
        case 'GET':
          responseFuture = _client.get(uri, headers: headers);
          break;
        case 'POST':
          responseFuture = _client.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          responseFuture = _client.put(uri, headers: headers, body: body);
          break;
        case 'PATCH':
          responseFuture = _client.patch(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          responseFuture = _client.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Método HTTP não suportado.');
      }
      final response =
          await responseFuture.timeout(const Duration(seconds: 15));
      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
            'Erro HTTP ${response.statusCode}. Confira a rota da API.');
      }
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
      throw ApiException('A API retornou uma resposta inválida.');
    } on TimeoutException {
      throw ApiException(
        'A API demorou para responder em $_baseUrl.',
      );
    } on http.ClientException {
      throw ApiException(
        'Não foi possível conectar à API em $_baseUrl.',
      );
    } catch (_) {
      throw ApiException(
        'Não foi possível conectar à API em $_baseUrl. '
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

  Future<Map<String, dynamic>?> obterPerfilUsuario() async =>
      await _request('GET', '/minha-conta') as Map<String, dynamic>;

  Future<dynamic> requisicao(String metodo, String caminho,
          {Map<String, dynamic>? dados}) =>
      _request(metodo, caminho, data: dados);

  Future<Uint8List> baixarArquivo(String caminho) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl$caminho'),
          headers: {
            'Authorization': 'Bearer ${SessionService.instance.token}'
          }).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw ApiException(
            'Não foi possível abrir o arquivo (${response.statusCode}).');
      }
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Não foi possível baixar o arquivo. Verifique a conexão.');
    }
  }

  Future<void> anexarExame(int pacienteId, Map<String, String> campos,
      Uint8List bytes, String nomeArquivo, String mime) async {
    try {
      final request = http.MultipartRequest('POST',
          Uri.parse('$_baseUrl/pacientes/$pacienteId/exames-documentos'))
        ..headers['Authorization'] = 'Bearer ${SessionService.instance.token}'
        ..fields.addAll(campos)
        ..files.add(http.MultipartFile.fromBytes('arquivo', bytes,
            filename: nomeArquivo, contentType: MediaType.parse(mime)));
      final response = await _client.send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 201) {
        final body = jsonDecode(response.body);
        throw ApiException(body is Map
            ? body['erro']?.toString() ?? 'Falha ao anexar exame.'
            : 'Falha ao anexar exame.');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Não foi possível enviar o arquivo. Verifique a conexão.');
    }
  }

  Future<Uint8List> baixarRelatorio(int ano, int mes) async {
    final id = SessionService.instance.pacienteId;
    final response = await _client.get(
        Uri.parse('$_baseUrl/pacientes/$id/relatorio.pdf?ano=$ano&mes=$mes'),
        headers: {
          'Authorization': 'Bearer ${SessionService.instance.token}'
        }).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        !response.headers['content-type']
            .toString()
            .contains('application/pdf')) {
      throw ApiException(
          'Não foi possível gerar o PDF (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  Future<List<Map<String, dynamic>>> _listar(String path) async {
    final scope = SessionService.instance.escopo;
    final result = await _request('GET', path) as List<dynamic>;
    // A API continua sendo a fonte de verdade; o cache não mascara falhas.
    if (SessionService.instance.escopo == scope) {
      unawaited(
          LocalStore.instance.put(scope, path, result).catchError((_) {}));
    }
    return result.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> criarMedicamento(
      Map<String, dynamic> dados) async {
    final id = SessionService.instance.pacienteId;
    return await _request('POST', '/pacientes/$id/medicamentos', data: dados)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listarMedicamentos() =>
      _listar('/pacientes/${SessionService.instance.pacienteId}/medicamentos');

  Future<Map<String, dynamic>> criarDiario(Map<String, dynamic> dados) async {
    final id = SessionService.instance.pacienteId;
    return await _request('POST', '/pacientes/$id/diarios-saude', data: dados)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listarDiarios() =>
      _listar('/pacientes/${SessionService.instance.pacienteId}/diarios-saude');

  Future<Map<String, dynamic>> criarRegistro(
          String recurso, Map<String, dynamic> dados) async =>
      await _request(
          'POST', '/pacientes/${SessionService.instance.pacienteId}/$recurso',
          data: dados) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listarRegistros(String recurso) =>
      _listar('/pacientes/${SessionService.instance.pacienteId}/$recurso');

  Future<void> atualizarRegistro(
      String recurso, Object registroId, Map<String, dynamic> dados) async {
    await _request('PATCH', '/$recurso/$registroId', data: dados);
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
      throw ApiException('A API retornou uma resposta inválida.');
    } catch (_) {
      throw ApiException(
          'Não foi possível conectar à API. Verifique se o backend está em execução.');
    }
  }
}
