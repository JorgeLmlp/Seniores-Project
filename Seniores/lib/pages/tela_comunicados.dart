import 'package:flutter/material.dart';

import '../models/comunicado.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Comunicados extends StatefulWidget {
  const Comunicados({super.key});

  @override
  State<Comunicados> createState() => _ComunicadosState();
}

class _ComunicadosState extends State<Comunicados> {
  final _api = ApiService();
  List<Comunicado> _comunicados = [];
  List<UsuarioVinculado> _destinatarios = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pacienteId = SessionService.instance.pacienteId;
      final dados = await Future.wait<Object?>([
        _api.listarComunicados(pacienteId),
        _api.obterCuidadorVinculado(pacienteId),
        _api.listarResponsaveisVinculados(pacienteId),
      ]);
      final destinatarios = <UsuarioVinculado>[];
      final cuidador = dados[1];
      if (cuidador is UsuarioVinculado) destinatarios.add(cuidador);
      destinatarios.addAll(dados[2] as List<UsuarioVinculado>);
      if (!mounted) return;
      setState(() {
        _comunicados = dados[0] as List<Comunicado>;
        _destinatarios = destinatarios;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar os comunicados.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirFormulario([Comunicado? comunicado]) async {
    final resultado = await showDialog<Comunicado>(
      context: context,
      builder: (_) => FormularioComunicado(
        comunicado: comunicado,
        destinatarios: _destinatarios,
      ),
    );
    if (resultado == null || !mounted) return;
    final identificadorTemporario = resultado.id ?? -DateTime.now().microsecondsSinceEpoch;
    final pendente = resultado.copyWith(
      id: identificadorTemporario,
      status: 'enviando',
      limparErro: true,
    );
    _substituirLocal(pendente);
    try {
      final salvo = resultado.id == null
          ? await _api.criarComunicado(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await _api.atualizarComunicado(resultado);
      if (!mounted) return;
      setState(() {
        _comunicados = [
          salvo,
          ..._comunicados.where((item) => item.id != identificadorTemporario),
        ];
      });
    } on ApiException catch (exception) {
      _marcarFalha(pendente, exception.message);
    } catch (_) {
      _marcarFalha(pendente, 'Não foi possível enviar o comunicado.');
    }
  }

  void _substituirLocal(Comunicado comunicado) {
    if (!mounted) return;
    setState(() {
      final indice = _comunicados.indexWhere((item) => item.id == comunicado.id);
      if (indice < 0) {
        _comunicados = [comunicado, ..._comunicados];
      } else {
        _comunicados[indice] = comunicado;
      }
    });
  }

  void _marcarFalha(Comunicado comunicado, String mensagem) {
    _substituirLocal(comunicado.copyWith(status: 'falhou', erro: mensagem));
    _mostrarMensagem(mensagem);
  }

  Future<void> _excluir(Comunicado comunicado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir comunicado?'),
        content: const Text('O comunicado será removido do histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || comunicado.id == null || !mounted) return;
    try {
      await _api.deletarComunicado(comunicado.id!);
      if (mounted) {
        setState(() {
          _comunicados.removeWhere((item) => item.id == comunicado.id);
        });
      }
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  Future<void> _reenviar(Comunicado comunicado) async {
    _substituirLocal(comunicado.copyWith(status: 'enviando', limparErro: true));
    try {
      final reenviado = comunicado.id == null || comunicado.id! < 0
          ? await _api.criarComunicado(
              SessionService.instance.pacienteId,
              comunicado,
            )
          : await _api.reenviarComunicado(comunicado.id!);
      if (!mounted) return;
      setState(() {
        final indice = _comunicados.indexWhere(
          (item) => item.id == reenviado.id,
        );
        if (indice >= 0) {
          _comunicados[indice] = reenviado;
        } else {
          _comunicados = [reenviado, ..._comunicados];
        }
      });
    } on ApiException catch (exception) {
      _marcarFalha(comunicado, exception.message);
    } catch (_) {
      _marcarFalha(comunicado, 'Não foi possível reenviar o comunicado.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunicados')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 280),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _erro != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            : _destinatarios.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'Vincule um cuidador ou responsável antes de enviar comunicados.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : _comunicados.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Nenhum comunicado enviado ainda.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _comunicados.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) => _card(_comunicados[index]),
              ),
      ),
      floatingActionButton: _destinatarios.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _abrirFormulario(),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _card(Comunicado comunicado) {
    final nomes = _destinatarios
        .where((item) => comunicado.destinatarios.contains(item.id))
        .map((item) => item.nome)
        .join(', ');
    return Card(
      child: ListTile(
        title: Text(comunicado.titulo),
        subtitle: Text(
          '${comunicado.mensagem}\nPara: ${nomes.isEmpty ? 'destinatário vinculado' : nomes}',
        ),
        isThreeLine: true,
        onTap: () => _abrirFormulario(comunicado),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusChip(comunicado),
            PopupMenuButton<String>(
              onSelected: (acao) {
                if (acao == 'editar') _abrirFormulario(comunicado);
                if (acao == 'reenviar') _reenviar(comunicado);
                if (acao == 'excluir') _excluir(comunicado);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'reenviar', child: Text('Reenviar')),
                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(Comunicado comunicado) {
    final (rotulo, cor, icone) = switch (comunicado.status) {
      'enviando' => ('Enviando', Colors.orange, Icons.sync),
      'falhou' => ('Falhou', Colors.red, Icons.error_outline),
      _ => ('Enviado', Colors.green, Icons.check_circle_outline),
    };
    return Tooltip(
      message: comunicado.erro ?? rotulo,
      child: Chip(
        avatar: Icon(icone, size: 16, color: cor),
        label: Text(rotulo),
        labelStyle: TextStyle(color: cor, fontSize: 12),
        side: BorderSide(color: cor.withValues(alpha: 0.35)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class FormularioComunicado extends StatefulWidget {
  final Comunicado? comunicado;
  final List<UsuarioVinculado> destinatarios;

  const FormularioComunicado({
    super.key,
    required this.destinatarios,
    this.comunicado,
  });

  @override
  State<FormularioComunicado> createState() => _FormularioComunicadoState();
}

class _FormularioComunicadoState extends State<FormularioComunicado> {
  late final TextEditingController _titulo;
  late final TextEditingController _mensagem;
  late final Set<int> _selecionados;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.comunicado?.titulo);
    _mensagem = TextEditingController(text: widget.comunicado?.mensagem);
    _selecionados = {...?widget.comunicado?.destinatarios};
  }

  @override
  void dispose() {
    _titulo.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_titulo.text.trim().isEmpty ||
        _mensagem.text.trim().isEmpty ||
        _selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe título, mensagem e destinatário.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Comunicado(
        id: widget.comunicado?.id,
        titulo: _titulo.text.trim(),
        mensagem: _mensagem.text.trim(),
        destinatarios: _selecionados.toList(),
        status: widget.comunicado?.status ?? 'enviado',
        erro: widget.comunicado?.erro,
        criadoEm: widget.comunicado?.criadoEm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.comunicado == null ? 'Novo comunicado' : 'Editar comunicado',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampoTexto(hintText: 'Título', controller: _titulo),
              const SizedBox(height: 10),
              CampoTexto(hintText: 'Mensagem', controller: _mensagem),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Destinatários',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...widget.destinatarios.map(
                (destinatario) => CheckboxListTile(
                  value: _selecionados.contains(destinatario.id),
                  title: Text(destinatario.nome),
                  subtitle: Text(destinatario.tipo),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (selecionado) => setState(() {
                    if (selecionado == true) {
                      _selecionados.add(destinatario.id);
                    } else {
                      _selecionados.remove(destinatario.id);
                    }
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        Botao(
          texto: 'Salvar',
          largura: 100,
          altura: 42,
          fontSize: 14,
          onPressed: _salvar,
        ),
      ],
    );
  }
}
