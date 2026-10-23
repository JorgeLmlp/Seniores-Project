import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/medicamento.dart';
import '../models/sinal_vital.dart';
import '../models/consulta.dart';
import '../models/exames.dart';
import '../models/item_estoque.dart';
import '../models/incidente.dart';
import '../models/higiene.dart';
import '../models/lesao.dart';
import '../models/dieta.dart';
import '../models/contato_emergencia.dart';
import '../models/alerta_emergencia.dart';
import '../models/registroDiario.dart';
import '../models/gasto.dart';
import '../models/notificacao.dart';
import '../models/usuario.dart';
import '../models/comunicado.dart';
import '../models/documento_exame.dart';
import '../models/administracao_medicamento.dart';
import 'session_service.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
}

class _SessionClient extends http.BaseClient {
  _SessionClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = SessionService.instance.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class ApiService {
  ApiService({http.Client? client})
    : _client = _SessionClient(client ?? http.Client());

  final http.BaseClient _client;
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  void _adicionarAutorizacao(http.BaseRequest request) {
    final token = SessionService.instance.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/users/login/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return body;
      throw ApiException(body['erro']?.toString() ?? 'Falha ao efetuar login.');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException('A API retornou uma resposta inválida.');
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException(
        'Não foi possível conectar à API. Verifique se ela está em execução.',
      );
    }
  }

  Future<Map<String, dynamic>> solicitarRecuperacaoSenha({
    required String email,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/users/password-reset/request'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return body;
      throw ApiException(
        body['erro']?.toString() ?? 'Falha ao solicitar recuperação.',
      );
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException('Falha ao solicitar recuperação de senha.');
    }
  }

  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/users/password-reset/confirm'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'nova_senha': novaSenha}),
          )
          .timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return;
      throw ApiException(
        body['erro']?.toString() ?? 'Falha ao redefinir senha.',
      );
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException('Falha ao redefinir senha.');
    }
  }

  Future<List<Comunicado>> listarComunicados(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/comunicados'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar comunicados.');
    }
    return body
        .map((item) => Comunicado.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Comunicado> criarComunicado(
    int pacienteId,
    Comunicado comunicado,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/comunicados'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(comunicado.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao enviar comunicado.'
            : 'Falha ao enviar comunicado.',
      );
    }
    return Comunicado.fromMap(body);
  }

  Future<Comunicado> atualizarComunicado(Comunicado comunicado) async {
    if (comunicado.id == null) {
      throw ApiException('Comunicado sem identificador para atualizar.');
    }
    final pacienteId = SessionService.instance.pacienteId;
    final response = await _client
        .patch(
          Uri.parse(
            '$baseUrl/pacientes/$pacienteId/comunicados/${comunicado.id}',
          ),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(comunicado.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao atualizar comunicado.'
            : 'Falha ao atualizar comunicado.',
      );
    }
    return Comunicado.fromMap(body);
  }

  Future<void> deletarComunicado(int comunicadoId) async {
    final pacienteId = SessionService.instance.pacienteId;
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/pacientes/$pacienteId/comunicados/$comunicadoId'),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir comunicado.');
    }
  }

  Future<Comunicado> reenviarComunicado(int comunicadoId) async {
    final pacienteId = SessionService.instance.pacienteId;
    final response = await _client
        .post(
          Uri.parse(
            '$baseUrl/pacientes/$pacienteId/comunicados/$comunicadoId/reenviar',
          ),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao reenviar comunicado.');
    }
    return Comunicado.fromMap(body);
  }

  Future<String> enviarRelatorioEmail(String email) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/historico/email'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'paciente_id': SessionService.instance.pacienteId,
            'email': email,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if ((response.statusCode != 202 && response.statusCode != 200) ||
        body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao enviar relatório.'
            : 'Falha ao enviar relatório.',
      );
    }
    return body['mensagem']?.toString() ?? 'Relatório enviado com sucesso.';
  }

  Future<List<DocumentoExame>> listarDocumentosExame(int exameId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/exames/$exameId/documentos'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar documentos do exame.');
    }
    return body
        .map((item) => DocumentoExame.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentoExame> enviarDocumentoExame({
    required int exameId,
    required String nome,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/exames/$exameId/documentos'),
    );
    _adicionarAutorizacao(request);
    request.files.add(
      http.MultipartFile.fromBytes('arquivo', bytes, filename: nome),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao enviar documento.'
            : 'Falha ao enviar documento.',
      );
    }
    return DocumentoExame.fromMap(body);
  }

  Future<void> deletarDocumentoExame(int documentoId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/documentos-exame/$documentoId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir documento.');
    }
  }

  Future<Medicamento> enviarFotoMedicamento({
    required int medicamentoId,
    required String nome,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/medicamentos/$medicamentoId/foto'),
    );
    _adicionarAutorizacao(request);
    request.files.add(
      http.MultipartFile.fromBytes('foto', bytes, filename: nome),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao enviar foto do medicamento.'
            : 'Falha ao enviar foto do medicamento.',
      );
    }
    return Medicamento.fromMap(body);
  }

  Future<void> deletarFotoMedicamento(int medicamentoId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/medicamentos/$medicamentoId/foto'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir foto do medicamento.');
    }
  }

  Future<List<AdministracaoMedicamento>> listarAdministracoes(
    int medicamentoId,
  ) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/medicamentos/$medicamentoId/administracoes'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar o histórico de doses.');
    }
    return body
        .map(
          (item) =>
              AdministracaoMedicamento.fromMap(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AdministracaoMedicamento> registrarAdministracao(
    AdministracaoMedicamento administracao,
  ) async {
    final response = await _client
        .post(
          Uri.parse(
            '$baseUrl/medicamentos/${administracao.medicamentoId}/administracoes',
          ),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(administracao.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao registrar a dose.'
            : 'Falha ao registrar a dose.',
      );
    }
    return AdministracaoMedicamento.fromMap(body);
  }

  Future<List<Medicamento>> listarMedicamentos(int pacienteId) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/pacientes/$pacienteId/medicamentos'))
          .timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw ApiException(
          body is Map
              ? body['erro']?.toString() ?? 'Falha ao carregar medicamentos.'
              : 'Falha ao carregar medicamentos.',
        );
      }
      return (body as List<dynamic>)
          .map((item) => Medicamento.fromMap(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException('Falha ao carregar medicamentos.');
    }
  }

  Future<Medicamento> criarMedicamento(
    int pacienteId,
    Medicamento medicamento,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/pacientes/$pacienteId/medicamentos'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(medicamento.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw ApiException(
          body is Map
              ? body['erro']?.toString() ?? 'Falha ao salvar medicamento.'
              : 'Falha ao salvar medicamento.',
        );
      }
      return Medicamento.fromMap(body as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException('Falha ao salvar medicamento.');
    }
  }

  Future<Medicamento> atualizarMedicamento(Medicamento medicamento) async {
    final id = medicamento.id;
    if (id == null) {
      throw ApiException('Medicamento sem identificador para atualizar.');
    }
    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/medicamentos/$id'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(medicamento.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode != 200 || body is! Map<String, dynamic>) {
        throw ApiException(
          body is Map
              ? body['erro']?.toString() ?? 'Falha ao atualizar medicamento.'
              : 'Falha ao atualizar medicamento.',
        );
      }
      return Medicamento.fromMap(body);
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException('Falha ao atualizar medicamento.');
    }
  }

  Future<void> deletarMedicamento(int medicamentoId) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/medicamentos/$medicamentoId'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 204) {
        final body = response.body.isEmpty ? null : jsonDecode(response.body);
        throw ApiException(
          body is Map
              ? body['erro']?.toString() ?? 'Falha ao excluir medicamento.'
              : 'Falha ao excluir medicamento.',
        );
      }
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('Não foi possível conectar à API.');
    } catch (_) {
      throw ApiException('Falha ao excluir medicamento.');
    }
  }

  Future<List<Consulta>> listarConsultas(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/consultas'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar consultas.');
    }
    return body
        .map((item) => Consulta.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Consulta> criarConsulta(int pacienteId, Consulta consulta) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/consultas'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(consulta.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar consulta.');
    }
    return Consulta.fromMap(body);
  }

  Future<Consulta> atualizarConsulta(Consulta consulta) async {
    final id = consulta.id;
    if (id == null) throw ApiException('Consulta sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/consultas/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(consulta.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar consulta.');
    }
    return Consulta.fromMap(body);
  }

  Future<void> deletarConsulta(int consultaId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/consultas/$consultaId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir consulta.');
    }
  }

  Future<List<Exame>> listarExames(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/exames'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar exames.');
    }
    return body
        .map((item) => Exame.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Exame> criarExame(int pacienteId, Exame exame) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/exames'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(exame.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar exame.');
    }
    return Exame.fromMap(body);
  }

  Future<Exame> atualizarExame(Exame exame) async {
    final id = exame.id;
    if (id == null) throw ApiException('Exame sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/exames/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(exame.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar exame.');
    }
    return Exame.fromMap(body);
  }

  Future<void> deletarExame(int exameId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/exames/$exameId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir exame.');
    }
  }

  Future<List<ItemEstoque>> listarEstoque(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/estoque'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar o estoque.');
    }
    return body
        .map((item) => ItemEstoque.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ItemEstoque> criarItemEstoque(int pacienteId, ItemEstoque item) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/estoque'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar item do estoque.');
    }
    return ItemEstoque.fromMap(body);
  }

  Future<ItemEstoque> atualizarItemEstoque(ItemEstoque item) async {
    final id = item.id;
    if (id == null) throw ApiException('Item sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/estoque/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar item do estoque.');
    }
    return ItemEstoque.fromMap(body);
  }

  Future<void> deletarItemEstoque(int itemId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/estoque/$itemId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir item do estoque.');
    }
  }

  Future<List<Incidente>> listarIncidentes(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/incidentes'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar incidentes.');
    }
    return body
        .map((item) => Incidente.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Incidente> criarIncidente(int pacienteId, Incidente incidente) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/incidentes'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(incidente.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar incidente.');
    }
    return Incidente.fromMap(body);
  }

  Future<Incidente> atualizarIncidente(Incidente incidente) async {
    final id = incidente.id;
    if (id == null) throw ApiException('Incidente sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/incidentes/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(incidente.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar incidente.');
    }
    return Incidente.fromMap(body);
  }

  Future<void> deletarIncidente(int incidenteId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/incidentes/$incidenteId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir incidente.');
    }
  }

  Future<List<Higiene>> listarHigienes(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/higiene'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar as rotinas de higiene.');
    }
    return body
        .map((item) => Higiene.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Higiene> criarHigiene(int pacienteId, Higiene higiene) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/higiene'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(higiene.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar a rotina de higiene.');
    }
    return Higiene.fromMap(body);
  }

  Future<Higiene> atualizarHigiene(Higiene higiene) async {
    final id = higiene.id;
    if (id == null) throw ApiException('Rotina de higiene sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/higiene/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(higiene.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar a rotina de higiene.');
    }
    return Higiene.fromMap(body);
  }

  Future<void> deletarHigiene(int higieneId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/higiene/$higieneId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir a rotina de higiene.');
    }
  }

  Future<List<Lesao>> listarLesoes(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/lesoes'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar as lesões.');
    }
    return body
        .map((item) => Lesao.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Lesao> criarLesao(int pacienteId, Lesao lesao) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/lesoes'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(lesao.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar a lesão.');
    }
    return Lesao.fromMap(body);
  }

  Future<Lesao> atualizarLesao(Lesao lesao) async {
    final id = lesao.id;
    if (id == null) throw ApiException('Lesão sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/lesoes/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(lesao.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar a lesão.');
    }
    return Lesao.fromMap(body);
  }

  Future<void> deletarLesao(int lesaoId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/lesoes/$lesaoId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir a lesão.');
    }
  }

  Future<Lesao> enviarFotoLesao({
    required int lesaoId,
    required String nome,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/lesoes/$lesaoId/foto'),
    );
    _adicionarAutorizacao(request);
    request.files.add(
      http.MultipartFile.fromBytes('foto', bytes, filename: nome),
    );
    final response = await request.send().timeout(const Duration(seconds: 30));
    final resposta = await http.Response.fromStream(response);
    final body = resposta.body.isEmpty ? null : jsonDecode(resposta.body);
    if (resposta.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao enviar a foto da lesão.');
    }
    return Lesao.fromMap(body);
  }

  Future<void> deletarFotoLesao(int lesaoId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/lesoes/$lesaoId/foto'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir a foto da lesão.');
    }
  }

  Future<List<Dieta>> listarDietas(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/dietas'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar as dietas.');
    }
    return body
        .map((item) => Dieta.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Dieta> criarDieta(int pacienteId, Dieta dieta) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/dietas'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(dieta.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar a dieta.');
    }
    return Dieta.fromMap(body);
  }

  Future<Dieta> atualizarDieta(Dieta dieta) async {
    final id = dieta.id;
    if (id == null) throw ApiException('Dieta sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/dietas/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(dieta.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar a dieta.');
    }
    return Dieta.fromMap(body);
  }

  Future<void> deletarDieta(int dietaId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/dietas/$dietaId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir a dieta.');
    }
  }

  Future<List<ContatoEmergencia>> listarContatosEmergencia(
    int pacienteId,
  ) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/contatos-emergencia'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar contatos de emergência.');
    }
    return body
        .map((item) => ContatoEmergencia.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ContatoEmergencia> criarContatoEmergencia(
    int pacienteId,
    ContatoEmergencia contato,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/contatos-emergencia'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(contato.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar contato de emergência.');
    }
    return ContatoEmergencia.fromMap(body);
  }

  Future<ContatoEmergencia> atualizarContatoEmergencia(
    ContatoEmergencia contato,
  ) async {
    final id = contato.id;
    if (id == null) throw ApiException('Contato sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/contatos-emergencia/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(contato.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar contato de emergência.');
    }
    return ContatoEmergencia.fromMap(body);
  }

  Future<void> deletarContatoEmergencia(int contatoId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/contatos-emergencia/$contatoId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir contato de emergência.');
    }
  }

  Future<List<AlertaEmergencia>> listarAlertasEmergencia(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/alertas-emergencia'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar alertas de emergência.');
    }
    return body
        .map((item) => AlertaEmergencia.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<AlertaEmergencia> criarAlertaEmergencia(
    int pacienteId,
    AlertaEmergencia alerta,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/alertas-emergencia'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(alerta.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao emitir alerta de emergência.');
    }
    return AlertaEmergencia.fromMap(body);
  }

  Future<AlertaEmergencia> resolverAlertaEmergencia(int alertaId) async {
    final response = await _client
        .patch(Uri.parse('$baseUrl/alertas-emergencia/$alertaId/resolver'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao resolver alerta de emergência.');
    }
    return AlertaEmergencia.fromMap(body);
  }

  Future<List<RegistroModel>> listarRegistrosDiarios(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/diario'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar o diário de saúde.');
    }
    return body
        .map((item) => RegistroModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<RegistroModel> criarRegistroDiario(
    int pacienteId,
    RegistroModel registro,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/diario'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(registro.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar o registro diário.');
    }
    return RegistroModel.fromMap(body);
  }

  Future<RegistroModel> atualizarRegistroDiario(RegistroModel registro) async {
    final id = registro.id;
    if (id == null) throw ApiException('Registro sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/diario/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(registro.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar o registro diário.');
    }
    return RegistroModel.fromMap(body);
  }

  Future<void> deletarRegistroDiario(int registroId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/diario/$registroId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir o registro diário.');
    }
  }

  Future<List<Gasto>> listarGastos(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/gastos'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar gastos.');
    }
    return body
        .map((item) => Gasto.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Gasto> criarGasto(int pacienteId, Gasto gasto) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/pacientes/$pacienteId/gastos'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(gasto.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao salvar gasto.');
    }
    return Gasto.fromMap(body);
  }

  Future<Gasto> atualizarGasto(Gasto gasto) async {
    final id = gasto.id;
    if (id == null) throw ApiException('Gasto sem identificador.');
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/gastos/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(gasto.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar gasto.');
    }
    return Gasto.fromMap(body);
  }

  Future<void> deletarGasto(int gastoId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/gastos/$gastoId'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir gasto.');
    }
  }

  Future<List<Notificacao>> listarNotificacoes(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/notificacoes'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar notificações.');
    }
    return body
        .map((item) => Notificacao.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Notificacao> marcarNotificacaoLida(int id) async {
    return _atualizarNotificacao(id, 'ler');
  }

  Future<Notificacao> marcarNotificacaoNaoLida(int id) async {
    return _atualizarNotificacao(id, 'nao-ler');
  }

  Future<Notificacao> _atualizarNotificacao(int id, String acao) async {
    final response = await _client
        .patch(Uri.parse('$baseUrl/notificacoes/$id/$acao'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ApiException('Falha ao atualizar notificação.');
    }
    return Notificacao.fromMap(body);
  }

  Future<UsuarioVinculado?> obterCuidadorVinculado(int pacienteId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/cuidador'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException('Falha ao carregar o cuidador.');
    }
    if (response.body.trim() == 'null' || response.body.trim().isEmpty) {
      return null;
    }
    return UsuarioVinculado.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<UsuarioVinculado>> listarResponsaveisVinculados(
    int pacienteId,
  ) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/pacientes/$pacienteId/responsaveis'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar responsáveis.');
    }
    return body
        .map((item) => UsuarioVinculado.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> desvincularCuidador(int pacienteId) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/pacientes/$pacienteId/cuidador'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao desvincular cuidador.');
    }
  }

  Future<void> desvincularResponsavel(int pacienteId, int responsavelId) async {
    final response = await _client
        .delete(
          Uri.parse(
            '$baseUrl/pacientes/$pacienteId/responsaveis/$responsavelId',
          ),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao desvincular responsável.');
    }
  }

  Future<void> vincularCuidador(String cpfPaciente, String cpfCuidador) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/relacionamentos/paciente-cuidador'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cpfPaciente': cpfPaciente,
            'cpfCuidador': cpfCuidador,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException('Falha ao vincular cuidador.');
    }
  }

  Future<void> vincularResponsavel(
    String cpfPaciente,
    String cpfResponsavel,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/registrar_relacionamento'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cpfPaciente': cpfPaciente,
            'cpfResponsavel': cpfResponsavel,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Falha ao vincular responsável.');
    }
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
      throw ApiException(
        'Nao foi possivel conectar a API. Verifique se o backend esta em execucao e a URL configurada.',
      );
    }
  }

  Future<Map<String, dynamic>> obterUsuario({
    required String tipo,
    required int usuarioId,
  }) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/users/$tipo/$usuarioId/'))
        .timeout(const Duration(seconds: 15));
    return _mapResponse(response, 200, 'Falha ao carregar a conta.');
  }

  Future<List<UsuarioVinculado>> listarPacientesVinculados() async {
    final session = SessionService.instance;
    if (session.tipoUsuario == 'paciente') {
      final usuario = await obterUsuario(
        tipo: 'paciente',
        usuarioId: session.usuarioId!,
      );
      return [UsuarioVinculado.fromMap(usuario)];
    }
    final filtro = session.tipoUsuario == 'cuidador'
        ? 'cuidador_id=${session.usuarioId}'
        : 'responsavel_id=${session.usuarioId}';
    final response = await _client
        .get(Uri.parse('$baseUrl/users/?tipo=paciente&$filtro'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar pacientes vinculados.');
    }
    return body
        .map((item) => UsuarioVinculado.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> atualizarUsuario({
    required String tipo,
    required int usuarioId,
    required Map<String, dynamic> dados,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/users/$tipo/$usuarioId/'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 15));
    return _mapResponse(response, 200, 'Falha ao atualizar a conta.');
  }

  Future<void> deletarUsuario({
    required String tipo,
    required int usuarioId,
  }) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/users/$tipo/$usuarioId/'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao excluir a conta.'
            : 'Falha ao excluir a conta.',
      );
    }
  }

  Future<List<SinalVital>> listarSinaisVitais() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/sinais-vitais'))
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200 || body is! List) {
      throw ApiException('Falha ao carregar sinais vitais.');
    }
    return body
        .map((item) => SinalVital.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<SinalVital> criarSinalVital(SinalVital sinal) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/sinais-vitais'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(sinal.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 201 || body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? 'Falha ao salvar sinal vital.'
            : 'Falha ao salvar sinal vital.',
      );
    }
    return SinalVital.fromMap(body);
  }

  Future<void> atualizarSinalVital(int id, SinalVital sinal) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/sinais-vitais/$id'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(sinal.toJson()),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException('Falha ao atualizar sinal vital.');
    }
  }

  Future<void> deletarSinalVital(int id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/sinais-vitais/$id'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 204) {
      throw ApiException('Falha ao excluir sinal vital.');
    }
  }

  Map<String, dynamic> _mapResponse(
    http.Response response,
    int statusEsperado,
    String mensagemPadrao,
  ) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != statusEsperado ||
        body is! Map<String, dynamic>) {
      throw ApiException(
        body is Map
            ? body['erro']?.toString() ?? mensagemPadrao
            : mensagemPadrao,
      );
    }
    return body;
  }
}
