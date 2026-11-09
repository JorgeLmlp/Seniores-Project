import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../models/recurso_cuidado.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../widgets/custom_card.dart';
import 'formulario_cuidado.dart';
import 'tela_evolucao_vital.dart';

class RegistrosCuidado extends StatefulWidget {
  const RegistrosCuidado({super.key, required this.recurso, this.api});
  final RecursoCuidado recurso;
  final ApiService? api;
  @override
  State<RegistrosCuidado> createState() => _RegistrosCuidadoState();
}

class _RegistrosCuidadoState extends State<RegistrosCuidado> {
  late final ApiService _api = widget.api ?? ApiService();
  late final int _pacienteId = SessionService.instance.pacienteId;
  late final String _pacienteNome = SessionService.instance.nomePaciente ??
      (SessionService.instance.tipoUsuario == 'paciente'
          ? SessionService.instance.nomeUsuario
          : null) ??
      'Paciente selecionado';
  List<Map<String, dynamic>> _registros = [];
  bool _carregando = true, _ocupado = false, _podeEscrever = false;
  String? _erro;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _podeEscrever = false;
    });
    try {
      final resultados = await Future.wait([
        _api.requisicao(
            'GET', '/pacientes/$_pacienteId/${widget.recurso.rota}'),
        _api.requisicao('GET', '/minha-conta/pacientes'),
      ]);
      final pacientes =
          (resultados[1] as List).where((p) => p['id'] == _pacienteId);
      if (mounted) {
        setState(() {
          _registros = (resultados[0] as List)
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          _podeEscrever =
              pacientes.isNotEmpty && pacientes.first['pode_escrever'] == true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e is ApiException
            ? e.message
            : 'Não foi possível carregar os registros.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editar([Map<String, dynamic>? registro]) async {
    final salvo = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => FormularioCuidado(
                recurso: widget.recurso,
                pacienteId: _pacienteId,
                api: _api,
                registro: registro)));
    if (salvo == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registro salvo.')));
      await _carregar();
    }
  }

  Future<void> _operacao(Future<void> Function() executar) async {
    setState(() => _ocupado = true);
    try {
      await executar();
      if (mounted) await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível concluir a operação.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _excluir(Map<String, dynamic> r) async {
    final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Excluir registro?'),
                content: Text('O registro “${_titulo(r)}” será removido.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Excluir'))
                ]));
    if (confirmado != true || !mounted) return;
    await _operacao(() async {
      await _api.requisicao('DELETE', '/${widget.recurso.rota}/${r['id']}');
    });
  }

  String _formatar(CampoCuidado c, dynamic valor) {
    if (valor == null || valor == '') return 'Não informado';
    if (c.tipo == TipoCampo.data) {
      final data = DateTime.tryParse(valor.toString());
      return data == null
          ? valor.toString()
          : DateFormat('dd/MM/yyyy HH:mm').format(data);
    }
    if (valor is List) {
      return valor.isEmpty
          ? 'Nenhum informado'
          : valor.map((v) => c.opcoes[v] ?? v).join(', ');
    }
    if (valor is bool) return valor ? 'Sim' : 'Não';
    return c.opcoes[valor] ?? valor.toString();
  }

  String _titulo(Map<String, dynamic> r) {
    final campo = widget.recurso.campos
        .firstWhere((c) => c.chave == widget.recurso.campoTitulo);
    return _formatar(campo, r[campo.chave]);
  }

  Future<void> _abrirArquivo(Map<String, dynamic> r) async {
    setState(() => _ocupado = true);
    try {
      final documento = widget.recurso.rota == 'exames-documentos';
      final caminho = documento
          ? '/exames-documentos/${r['id']}/arquivo'
          : '/lesoes/${r['id']}/foto';
      final bytes = await _api.baixarArquivo(caminho);
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(_titulo(r))),
                    body: documento && r['mime_type'] == 'application/pdf'
                        ? PdfPreview(
                            build: (_) async => bytes,
                            canChangeOrientation: false,
                            canChangePageFormat: false)
                        : Center(
                            child: InteractiveViewer(
                                child: Image.memory(bytes,
                                    errorBuilder: (_, __, ___) => const Text(
                                        'Não foi possível exibir esta imagem.')))),
                  )));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível abrir o arquivo.')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Widget _cartao(Map<String, dynamic> r) {
    final recurso = widget.recurso;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CardPadrao(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(recurso.icone, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_titulo(r),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold))),
            if (_podeEscrever)
              PopupMenuButton<String>(
                  enabled: !_ocupado,
                  tooltip: 'Ações do registro',
                  onSelected: (v) => v == 'editar' ? _editar(r) : _excluir(r),
                  itemBuilder: (_) => [
                        if (recurso.rota != 'exames-documentos')
                          const PopupMenuItem(
                              value: 'editar', child: Text('Editar')),
                        const PopupMenuItem(
                            value: 'excluir', child: Text('Excluir'))
                      ]),
          ]),
          const Divider(height: 24),
          for (final c
              in recurso.campos.where((c) => c.chave != recurso.campoTitulo))
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '${c.rotulo}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: _formatar(c, r[c.chave])),
                ]))),
          if (r['estoque_baixo'] == true)
            const Chip(
                avatar: Icon(Icons.warning_amber_rounded),
                label: Text('Estoque baixo')),
          if (recurso.rota == 'checklists-higiene' && _podeEscrever)
            OutlinedButton.icon(
                onPressed: _ocupado
                    ? null
                    : () => _operacao(() async {
                          await _api.atualizarRegistro(recurso.rota, r['id'], {
                            'status': r['status'] == 'concluida'
                                ? 'pendente'
                                : 'concluida'
                          });
                        }),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(r['status'] == 'concluida'
                    ? 'Marcar como pendente'
                    : 'Concluir tarefa')),
          if (recurso.rota == 'alertas-panico' &&
              r['resolvido'] != true &&
              _podeEscrever)
            OutlinedButton.icon(
                onPressed: _ocupado
                    ? null
                    : () => _operacao(() async {
                          await _api.atualizarRegistro(
                              recurso.rota, r['id'], {'resolvido': true});
                        }),
                icon: const Icon(Icons.check),
                label: const Text('Concluir atendimento')),
          if (recurso.rota == 'exames-documentos' || r['foto_url'] != null)
            OutlinedButton.icon(
                onPressed: _ocupado ? null : () => _abrirArquivo(r),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Visualizar anexo')),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = _registros
        .where((r) => widget.recurso.campos.any((c) => _formatar(c, r[c.chave])
            .toLowerCase()
            .contains(_busca.toLowerCase())))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.recurso.titulo), actions: [
        IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando || _ocupado ? null : _carregar,
            icon: const Icon(Icons.refresh))
      ]),
      floatingActionButton: _podeEscrever && _erro == null && !_carregando
          ? FloatingActionButton.extended(
              onPressed: _ocupado ? null : () => _editar(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'))
          : null,
      body: RefreshIndicator(
          onRefresh: _carregar,
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  Text(_pacienteNome,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(widget.recurso.descricao),
                  const SizedBox(height: 20),
                  if (_carregando || _ocupado) const LinearProgressIndicator(),
                  if (_erro != null) ...[
                    Text(_erro!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    TextButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'))
                  ],
                  if (!_carregando && _erro == null) ...[
                    if (!_podeEscrever)
                      const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                              'Somente leitura. O responsável pode autorizar alterações nas permissões.')),
                    if (widget.recurso.rota == 'sinais-vitais')
                      OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EvolucaoVital(
                                      api: _api, pacienteId: _pacienteId))),
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Ver evolução')),
                    if (_registros.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: TextField(
                              decoration: const InputDecoration(
                                  labelText: 'Buscar registros',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder()),
                              onChanged: (v) => setState(() => _busca = v))),
                    if (visiveis.isEmpty)
                      CardPadrao(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(children: [
                                Icon(widget.recurso.icone, size: 44),
                                const SizedBox(height: 12),
                                Text(_registros.isEmpty
                                    ? 'Nenhum registro cadastrado.'
                                    : 'Nenhum resultado para esta busca.'),
                                if (_registros.isEmpty && _podeEscrever)
                                  const Text(
                                      'Use Adicionar para criar o primeiro registro.'),
                              ]))),
                    ...visiveis.map(_cartao),
                  ],
                ]),
          ))),
    );
  }
}
