import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import 'local_store.dart';
import 'session_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
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

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SessionService.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final headers = _headers();
      final body = data == null ? null : jsonEncode(data);
      late Future<http.Response> responseFuture;
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
          responseFuture = _client.delete(uri, headers: headers, body: body);
          break;
        default:
          throw ArgumentError('Método HTTP não suportado.');
      }
      final response = await responseFuture.timeout(
        const Duration(seconds: 15),
      );
      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
          'Erro HTTP ${response.statusCode}. Confira a rota da API.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      final message =
          decoded is Map<String, dynamic> ? decoded['erro'] as String? : null;
      if (response.statusCode == 401 && path != '/users/login/') {
        await SessionService.instance.encerrar();
        throw ApiException(
          'Sua sessão expirou. Entre novamente.',
          statusCode: response.statusCode,
        );
      }
      throw ApiException(
        message ?? 'Falha ao comunicar com a API.',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on StateError catch (error) {
      throw ApiException(error.message);
    } on FormatException {
      throw ApiException('A API retornou uma resposta inválida.');
    } on TimeoutException {
      throw ApiException('A API demorou para responder em $_baseUrl.');
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API em $_baseUrl.');
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
    required bool manterConectado,
  }) async {
    final result = await _request(
      'POST',
      '/users/login/',
      data: {'email': email, 'senha': senha},
    ) as Map<String, dynamic>;
    await SessionService.instance.iniciarLogin(
      result,
      persistir: manterConectado,
    );
    return result;
  }

  Future<Map<String, dynamic>?> obterPerfilUsuario() async =>
      await _request('GET', '/minha-conta') as Map<String, dynamic>;

  Future<dynamic> requisicao(
    String metodo,
    String caminho, {
    Map<String, dynamic>? dados,
  }) =>
      _request(metodo, caminho, data: dados);

  Future<Uint8List> baixarRelatorio(int ano, int mes) async {
    final id = SessionService.instance.pacienteId;
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/pacientes/$id/relatorio.pdf?ano=$ano&mes=$mes'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) {
      await SessionService.instance.encerrar();
      throw ApiException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
      );
    }
    if (response.statusCode != 200 ||
        !response.headers['content-type'].toString().contains(
              'application/pdf',
            )) {
      throw ApiException(
        'Não foi possível gerar o PDF (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  /// Envia documento clinico multipart, mantendo o token na requisicao.
  Future<Map<String, dynamic>> enviarDocumentoExame({
    required String nome,
    required String nomeArquivo,
    required Uint8List conteudo,
    required String mime,
  }) async {
    final id = SessionService.instance.pacienteId;
    final uri = Uri.parse('$_baseUrl/pacientes/$id/exames-documentos');
    final requisicao = http.MultipartRequest('POST', uri);
    final token = SessionService.instance.accessToken;
    if (token != null) requisicao.headers['Authorization'] = 'Bearer $token';
    requisicao.fields['nome'] = nome;
    requisicao.files.add(http.MultipartFile.fromBytes('arquivo', conteudo,
      filename: nomeArquivo,
      contentType: http_parser.MediaType.parse(mime)));
    final resposta = await http.Response.fromStream(
      await _client.send(requisicao).timeout(const Duration(seconds: 40)));
    if (resposta.statusCode != 201) {
      throw ApiException('Falha ao enviar documento (${resposta.statusCode}).',
        statusCode: resposta.statusCode);
    }
    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }

  Future<Uint8List> baixarArquivo(String caminho) async {
    if (!caminho.startsWith('/') || caminho.startsWith('//')) {
      throw ApiException('Caminho do documento inválido.');
    }
    final resposta = await _client.get(Uri.parse('$_baseUrl$caminho'),
      headers: _headers()).timeout(const Duration(seconds: 30));
    if (resposta.statusCode != 200) {
      throw ApiException('Não foi possível baixar o documento (${resposta.statusCode}).',
        statusCode: resposta.statusCode);
    }
    return resposta.bodyBytes;
  }

  Future<List<Map<String, dynamic>>> _listar(String path) async {
    final scope = SessionService.instance.escopo;
    final result = await _request('GET', path) as List<dynamic>;
    if (SessionService.instance.escopo == scope) {
      unawaited(
        LocalStore.instance.put(scope, path, result).catchError((_) {}),
      );
    }
    return result.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> criarMedicamento(
    Map<String, dynamic> dados,
  ) async {
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
    String recurso,
    Map<String, dynamic> dados,
  ) async =>
      await _request(
        'POST',
        '/pacientes/${SessionService.instance.pacienteId}/$recurso',
        data: dados,
      ) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> listarRegistros(String recurso) =>
      _listar('/pacientes/${SessionService.instance.pacienteId}/$recurso');

  Future<void> atualizarRegistro(
    String recurso,
    Object registroId,
    Map<String, dynamic> dados,
  ) async {
    await _request('PATCH', '/$recurso/$registroId', data: dados);
  }

  Future<void> excluirRegistro(String recurso, Object registroId) async {
    await _request('DELETE', '/$recurso/$registroId');
  }

  Future<void> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
    required String cpf,
    required String tipo,
    int? idade,
    String? tipoSanguineo,
    Map<String, dynamic>? preferencias,
  }) async {
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
        if (idade != null) 'idade': idade,
        if (tipoSanguineo != null) 'tipo_sanguineo': tipoSanguineo,
        if (preferencias != null) 'preferencias': preferencias,
      },
    );
  }
}
