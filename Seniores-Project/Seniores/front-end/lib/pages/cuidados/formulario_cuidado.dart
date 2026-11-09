import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/recurso_cuidado.dart';
import '../../services/api_service.dart';

class FormularioCuidado extends StatefulWidget {
  const FormularioCuidado(
      {super.key,
      required this.recurso,
      required this.pacienteId,
      required this.api,
      this.registro});
  final RecursoCuidado recurso;
  final int pacienteId;
  final ApiService api;
  final Map<String, dynamic>? registro;
  @override
  State<FormularioCuidado> createState() => _FormularioCuidadoState();
}

class _FormularioCuidadoState extends State<FormularioCuidado> {
  final _form = GlobalKey<FormState>();
  final _controles = <String, TextEditingController>{};
  final _valores = <String, dynamic>{};
  bool _salvando = false, _selecionando = false, _removerFoto = false;
  String? _erro, _nomeArquivo, _mime;
  Uint8List? _arquivo;
  bool get _documento => widget.recurso.rota == 'exames-documentos';
  bool get _lesao => widget.recurso.rota == 'lesoes';

  @override
  void initState() {
    super.initState();
    for (final c in widget.recurso.campos) {
      final valor = widget.registro?[c.chave];
      _controles[c.chave] = TextEditingController(
          text: valor is List ? valor.join(', ') : valor?.toString() ?? '');
      _valores[c.chave] = switch (c.tipo) {
        TipoCampo.booleano => valor == true,
        TipoCampo.opcao => valor ?? c.opcoes.keys.first,
        TipoCampo.lista =>
          valor is List ? List<String>.from(valor) : <String>[],
        TipoCampo.data => valor == null
            ? (c.obrigatorio ? DateTime.now() : null)
            : DateTime.tryParse(valor.toString()),
        _ => valor,
      };
    }
  }

  @override
  void dispose() {
    for (final c in _controles.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    setState(() {
      _selecionando = true;
      _erro = null;
    });
    try {
      final file = await openFile(acceptedTypeGroups: [
        XTypeGroup(
          label: _documento ? 'Exame' : 'Fotografia',
          extensions: [
            'jpg',
            'jpeg',
            'png',
            'webp',
            if (_documento) 'pdf' else 'gif'
          ],
          uniformTypeIdentifiers: [
            'public.image',
            if (_documento) 'com.adobe.pdf'
          ],
        )
      ]);
      if (file == null) return;
      final limite = (_documento ? 10 : 5) * 1024 * 1024;
      final tamanho = await file.length();
      if (tamanho == 0 || tamanho > limite) {
        throw ApiException(
            'Selecione um arquivo de até ${_documento ? 10 : 5} MB, que não esteja vazio.');
      }
      final ext = file.name.split('.').last.toLowerCase();
      final mime = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        if (_documento) 'pdf': 'application/pdf' else 'gif': 'image/gif'
      }[ext];
      if (mime == null) throw ApiException('Formato de arquivo não aceito.');
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _arquivo = bytes;
          _nomeArquivo = file.name;
          _mime = mime;
          _removerFoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e is ApiException
            ? e.message
            : 'Não foi possível selecionar o arquivo.');
      }
    } finally {
      if (mounted) setState(() => _selecionando = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_documento && _arquivo == null) {
      setState(() => _erro = 'Selecione o arquivo do exame.');
      return;
    }
    final dados = <String, dynamic>{};
    for (final c in widget.recurso.campos) {
      final texto = _controles[c.chave]!.text.trim();
      dados[c.chave] = switch (c.tipo) {
        TipoCampo.inteiro => texto.isEmpty ? null : int.parse(texto),
        TipoCampo.decimal => texto.isEmpty ? null : texto.replaceAll(',', '.'),
        TipoCampo.lista => c.opcoes.isEmpty
            ? texto
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : _valores[c.chave],
        TipoCampo.data => (_valores[c.chave] as DateTime?)?.toIso8601String(),
        TipoCampo.opcao || TipoCampo.booleano => _valores[c.chave],
        _ => texto,
      };
    }
    if (widget.recurso.rota == 'sinais-vitais' &&
        ![
          'pressao_art',
          'glicemia',
          'temperatura',
          'freq_cardiaca',
          'saturacao'
        ].any((c) => dados[c] != null && dados[c].toString().isNotEmpty)) {
      setState(() => _erro = 'Informe pelo menos uma medição.');
      return;
    }
    if (_lesao) {
      if (_arquivo != null) {
        dados['foto_base64'] = 'data:$_mime;base64,${base64Encode(_arquivo!)}';
      }
      if (_removerFoto) dados['foto_base64'] = null;
    }
    // A API não aceita null para quantidade mínima; zero representa limite zero.
    if (widget.recurso.rota == 'estoque' &&
        dados['quantidade_minima'] == null) {
      dados.remove('quantidade_minima');
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      if (_documento) {
        await widget.api.anexarExame(
            widget.pacienteId,
            {
              for (final e in dados.entries)
                if (e.value != null) e.key: e.value.toString()
            },
            _arquivo!,
            _nomeArquivo!,
            _mime!);
      } else {
        await widget.api.requisicao(
            widget.registro == null ? 'POST' : 'PATCH',
            widget.registro == null
                ? '/pacientes/${widget.pacienteId}/${widget.recurso.rota}'
                : '/${widget.recurso.rota}/${widget.registro!['id']}',
            dados: dados);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e is ApiException
            ? e.message
            : 'Não foi possível salvar o registro.');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarData(CampoCuidado campo) async {
    final atual = _valores[campo.chave] as DateTime? ?? DateTime.now();
    final data = await showDatePicker(
        context: context,
        initialDate: atual,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(atual));
    if (hora != null && mounted) {
      setState(() => _valores[campo.chave] =
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute));
    }
  }

  Widget _campo(CampoCuidado c) {
    final label = '${c.rotulo}${c.obrigatorio ? ' *' : ''}';
    final decoration = InputDecoration(
        labelText: label,
        helperText: c.ajuda,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
    if (c.tipo == TipoCampo.booleano) {
      return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: _valores[c.chave] == true,
          onChanged: (v) => setState(() => _valores[c.chave] = v));
    }
    if (c.tipo == TipoCampo.opcao) {
      final opcoes = {...c.opcoes};
      final atual = _valores[c.chave] as String;
      opcoes.putIfAbsent(atual, () => atual);
      return DropdownButtonFormField<String>(
          initialValue: atual,
          decoration: decoration,
          isExpanded: true,
          items: opcoes.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => _valores[c.chave] = v);
    }
    if (c.tipo == TipoCampo.lista && c.opcoes.isNotEmpty) {
      return FormField<List<String>>(
          validator: (_) => c.obrigatorio && (_valores[c.chave] as List).isEmpty
              ? 'Selecione pelo menos um dia.'
              : null,
          builder: (state) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    children: c.opcoes.entries
                        .map((e) => FilterChip(
                              label: Text(e.value),
                              selected:
                                  (_valores[c.chave] as List).contains(e.key),
                              onSelected: (v) => setState(() {
                                final dias = _valores[c.chave] as List;
                                v ? dias.add(e.key) : dias.remove(e.key);
                                state.didChange(List<String>.from(dias));
                              }),
                            ))
                        .toList()),
                if (state.hasError)
                  Text(state.errorText!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
              ]));
    }
    if (c.tipo == TipoCampo.data) {
      final data = _valores[c.chave] as DateTime?;
      return FormField<DateTime>(
          validator: (_) =>
              c.obrigatorio && data == null ? 'Informe a data.' : null,
          builder: (state) => InputDecorator(
              decoration: decoration.copyWith(errorText: state.errorText),
              child: Row(children: [
                Expanded(
                    child: TextButton.icon(
                        onPressed: () => _selecionarData(c),
                        icon: const Icon(Icons.event_outlined),
                        label: Text(data == null
                            ? 'Selecionar data'
                            : DateFormat('dd/MM/yyyy HH:mm').format(data)))),
                if (!c.obrigatorio && data != null)
                  IconButton(
                      tooltip: 'Remover data',
                      onPressed: () => setState(() => _valores[c.chave] = null),
                      icon: const Icon(Icons.clear)),
              ])));
    }
    return TextFormField(
        controller: _controles[c.chave],
        decoration: decoration,
        readOnly: c.tipo == TipoCampo.hora,
        onTap: c.tipo != TipoCampo.hora
            ? null
            : () async {
                final partes = _controles[c.chave]!.text.split(':');
                final hora = await showTimePicker(
                    context: context,
                    initialTime: partes.length == 2
                        ? TimeOfDay(
                            hour: int.tryParse(partes[0]) ?? 8,
                            minute: int.tryParse(partes[1]) ?? 0)
                        : const TimeOfDay(hour: 8, minute: 0));
                if (hora != null && mounted) {
                  _controles[c.chave]!.text =
                      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                }
              },
        keyboardType: c.tipo == TipoCampo.inteiro || c.tipo == TipoCampo.decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : c.chave == 'telefone'
                ? TextInputType.phone
                : c.chave == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.text,
        minLines: 1,
        maxLines: c.tipo == TipoCampo.texto &&
                c.chave != 'email' &&
                c.chave != 'telefone'
            ? 4
            : 1,
        validator: (v) {
          final texto = v?.trim() ?? '';
          if (texto.isEmpty) {
            return c.obrigatorio ? 'Preencha este campo.' : null;
          }
          if (c.tipo == TipoCampo.inteiro || c.tipo == TipoCampo.decimal) {
            final n = c.tipo == TipoCampo.inteiro
                ? int.tryParse(texto)
                : double.tryParse(texto.replaceAll(',', '.'));
            if (n == null || !n.isFinite || n < 0) {
              return 'Informe um número ${c.tipo == TipoCampo.inteiro ? 'inteiro ' : ''}não negativo.';
            }
            if (c.maximo != null && n > c.maximo!) {
              return 'O valor máximo é ${c.maximo}.';
            }
          } else if (c.maximo != null && texto.length > c.maximo!) {
            return 'Use até ${c.maximo} caracteres.';
          }
          if (c.chave == 'email' &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(texto)) {
            return 'Informe um e-mail válido.';
          }
          if (c.chave == 'pressao_art' &&
              !RegExp(r'^\d{1,3}/\d{1,3}$').hasMatch(texto)) {
            return 'Use o formato 120/80.';
          }
          return null;
        });
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_salvando,
      child: Scaffold(
        appBar: AppBar(
            title: Text(
                '${widget.registro == null ? 'Adicionar' : 'Editar'} · ${widget.recurso.titulo}')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                    key: _form,
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
                      Text(widget.recurso.descricao),
                      const SizedBox(height: 20),
                      AbsorbPointer(
                          absorbing: _salvando,
                          child: Column(children: [
                            for (final c in widget.recurso.campos)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _campo(c)),
                            if (_documento || _lesao) ...[
                              OutlinedButton.icon(
                                  onPressed:
                                      _selecionando ? null : _selecionarArquivo,
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(_selecionando
                                      ? 'Selecionando...'
                                      : 'Selecionar ${_documento ? 'arquivo' : 'foto'}')),
                              Text(_nomeArquivo ??
                                  (_documento
                                      ? 'PDF, JPEG, PNG ou WebP • até 10 MB'
                                      : 'JPEG, PNG, WebP ou GIF • até 5 MB')),
                              if (_arquivo != null ||
                                  (_lesao &&
                                      widget.registro?['foto_url'] != null &&
                                      !_removerFoto))
                                TextButton(
                                    onPressed: () => setState(() {
                                          _arquivo = null;
                                          _nomeArquivo = null;
                                          _removerFoto = true;
                                        }),
                                    child: const Text('Remover anexo')),
                              const SizedBox(height: 20),
                            ],
                          ])),
                      if (_erro != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_erro!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      FilledButton.icon(
                          onPressed:
                              _salvando || _selecionando ? null : _salvar,
                          icon: const Icon(Icons.check),
                          label: Text(
                              _salvando ? 'Salvando...' : 'Salvar registro')),
                    ])))),
      ));
}
