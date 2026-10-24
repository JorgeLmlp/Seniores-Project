import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/acoes_externas.dart';

/// CRUD compartilhado para recursos ja suportados pela API do Seniores.
/// Nao representa diagnostico nem fornece orientacoes de tratamento.
enum TipoCampo { texto, numero, lista, escolha, data }

class CampoClinico {
  const CampoClinico(this.chave, this.rotulo,
      {this.tipo = TipoCampo.texto, this.obrigatorio = false, this.opcoes = const []});
  final String chave;
  final String rotulo;
  final TipoCampo tipo;
  final bool obrigatorio;
  final List<String> opcoes;
}

class ModuloClinicoConfig {
  const ModuloClinicoConfig(this.titulo, this.recurso, this.icone, this.campos,
      {this.aviso, this.grafico = false});
  final String titulo;
  final String recurso;
  final IconData icone;
  final List<CampoClinico> campos;
  final String? aviso;
  final bool grafico;
}

class ModulosSeniores {
  static const sinais = ModuloClinicoConfig(
    'Sinais vitais', 'sinais-vitais', Icons.monitor_heart_outlined, [
      CampoClinico('pressao_art', 'Pressão arterial (ex.: 120/80)'),
      CampoClinico('glicemia', 'Glicemia (informe unidade)'),
      CampoClinico('temperatura', 'Temperatura em °C'),
      CampoClinico('freq_cardiaca', 'Frequência cardíaca (bpm)'),
      CampoClinico('saturacao', 'Saturação (%)'),
      CampoClinico('data', 'Data/hora da medição', tipo: TipoCampo.data),
    ],
    aviso: 'Os valores são registros informados. Esta tela não interpreta medidas nem substitui avaliação profissional.',
    grafico: true,
  );
  static const estoque = ModuloClinicoConfig(
    'Estoque de insumos', 'estoque', Icons.inventory_2_outlined, [
      CampoClinico('nome', 'Nome do item', obrigatorio: true),
      CampoClinico('quantidade', 'Quantidade disponível', tipo: TipoCampo.numero, obrigatorio: true),
      CampoClinico('quantidade_minima', 'Quantidade mínima', tipo: TipoCampo.numero),
      CampoClinico('descricao', 'Descrição'),
    ],
  );
  static const incidentes = ModuloClinicoConfig(
    'Incidentes', 'incidentes', Icons.report_outlined, [
      CampoClinico('tipo', 'Tipo de ocorrência', obrigatorio: true),
      CampoClinico('data_hora', 'Data/hora', tipo: TipoCampo.data, obrigatorio: true),
      CampoClinico('descricao', 'Descrição do ocorrido', obrigatorio: true),
      CampoClinico('gravidade', 'Gravidade informada'),
      CampoClinico('providencias', 'Providências adotadas'),
    ],
  );
  static const contatos = ModuloClinicoConfig(
    'Contatos de emergência', 'contatos-emergencia', Icons.contact_emergency_outlined, [
      CampoClinico('nome', 'Nome', obrigatorio: true),
      CampoClinico('tipo', 'Tipo', obrigatorio: true, tipo: TipoCampo.escolha,
          opcoes: ['familiar', 'medico']),
      CampoClinico('telefone', 'Telefone', obrigatorio: true),
      CampoClinico('vinculo', 'Vínculo'),
      CampoClinico('email', 'E-mail'),
      CampoClinico('especialidade', 'Especialidade (se médico)'),
    ],
    aviso: 'Estes contatos ficam registrados no Seniores. Cadastrá-los não envia mensagens ou ligações automaticamente.',
  );
  static const dietas = ModuloClinicoConfig(
    'Dietas e restrições', 'dietas-restricoes', Icons.restaurant_outlined, [
      CampoClinico('descricao_dieta', 'Descrição da dieta'),
      CampoClinico('restricoes', 'Restrições (separe por vírgula)', tipo: TipoCampo.lista, obrigatorio: true),
      CampoClinico('alergias', 'Alergias (separe por vírgula)', tipo: TipoCampo.lista),
      CampoClinico('observacoes', 'Observações'),
    ],
  );
  static const higiene = ModuloClinicoConfig(
    'Checklist de higiene', 'checklists-higiene', Icons.clean_hands_outlined, [
      CampoClinico('tarefa', 'Tarefa', obrigatorio: true),
      CampoClinico('descricao', 'Descrição', obrigatorio: true),
      CampoClinico('frequencia', 'Frequência', obrigatorio: true),
      CampoClinico('status', 'Status', tipo: TipoCampo.escolha,
          opcoes: ['pendente', 'concluida']),
    ],
  );
  static const lesoes = ModuloClinicoConfig(
    'Acompanhamento de lesões', 'lesoes', Icons.healing_outlined, [
      CampoClinico('localizacao', 'Localização', obrigatorio: true),
      CampoClinico('descricao', 'Descrição', obrigatorio: true),
      CampoClinico('gravidade', 'Gravidade informada'),
      CampoClinico('status', 'Status'),
    ],
    aviso: 'Registre informações observadas. A avaliação ou tratamento de lesões deve ser feito por profissional habilitado.',
  );
  static const alertas = ModuloClinicoConfig(
    'Histórico de alertas', 'alertas-panico', Icons.notification_important_outlined, [
      CampoClinico('mensagem', 'Mensagem'),
      CampoClinico('resolvido', 'Estado', tipo: TipoCampo.escolha, opcoes: ['pendente', 'resolvido']),
      CampoClinico('localizacao', 'Localização informada'),
    ],
    aviso: 'ATENÇÃO: salvar um alerta aqui NÃO chama emergência nem avisa contatos. Para ajuda imediata, use os canais de emergência disponíveis.',
  );
}

class ModuloClinico extends StatefulWidget {
  const ModuloClinico({super.key, required this.config, this.registroDestaque});
  final ModuloClinicoConfig config;
  final int? registroDestaque;

  @override
  State<ModuloClinico> createState() => _ModuloClinicoState();
}

class _ModuloClinicoState extends State<ModuloClinico> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final lista = await _api.listarRegistros(widget.config.recurso);
      lista.sort((a, b) {
        if (a['id'] == widget.registroDestaque) return -1;
        if (b['id'] == widget.registroDestaque) return 1;
        return (int.tryParse('${b['id']}') ?? 0)
          .compareTo(int.tryParse('${a['id']}') ?? 0);
      });
      if (mounted) setState(() => _itens = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Não foi possível carregar os registros.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _formulario([Map<String, dynamic>? atual]) async {
    final mudou = await showDialog<bool>(
      context: context,
      builder: (context) => _FormularioClinico(config: widget.config, api: _api, atual: atual),
    );
    if (mudou == true && mounted) await _carregar();
  }

  Future<void> _excluir(Map<String, dynamic> item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text('Esta ação não poderá ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await _api.excluirRegistro(widget.config.recurso, item['id']);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Erro ao excluir.')),
      );
    }
  }

  Future<void> _ajustarEstoque(Map<String, dynamic> item, int incremento) async {
    final quantidade = (item['quantidade'] as num?)?.toInt() ?? 0;
    final novoValor = quantidade + incremento;
    if (novoValor < 0) return;
    try {
      await _api.atualizarRegistro('estoque', item['id'], {'quantidade': novoValor});
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Erro ao atualizar estoque.')));
    }
  }

  Future<void> _acionarAlerta() async {
    final confirmado = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Registrar alerta de emergência?'),
      content: const Text('O alerta será registrado, mas isso não chama socorro nem envia mensagem automaticamente. '
        'Se precisar de atendimento imediato, utilize os serviços de emergência disponíveis.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar alerta'))]));
    if (confirmado != true) return;
    await _formulario();
  }

  Future<void> _resolverAlerta(Map<String, dynamic> item) async {
    try {
      await _api.atualizarRegistro('alertas-panico', item['id'], {'resolvido': true});
      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Não foi possível resolver o alerta.')));
      }
    }
  }

  String _titulo(Map<String, dynamic> item) {
    for (final chave in ['nome', 'tipo', 'tarefa', 'localizacao', 'pressao_art', 'descricao_dieta', 'mensagem']) {
      if ('${item[chave] ?? ''}'.trim().isNotEmpty) return '${item[chave]}';
    }
    return 'Registro ${item['id'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return Scaffold(
      appBar: AppBar(title: Text(c.titulo)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: c.recurso == 'alertas-panico' ? _acionarAlerta : () => _formulario(),
        tooltip: 'Cadastrar ${c.titulo}',
        icon: const Icon(Icons.add), label: const Text('Cadastrar'),
      ),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: RefreshIndicator(
          onRefresh: _carregar,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (c.aviso != null) Card(color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(padding: const EdgeInsets.all(16), child: Text(c.aviso!))),
            if (c.grafico && _itens.isNotEmpty) _GraficoSinais(itens: _itens),
            if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            if (_erro != null) Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              Text(_erro!, textAlign: TextAlign.center),
              TextButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
            ]))),
            if (!_carregando && _erro == null && _itens.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Nenhum registro cadastrado.'))),
            if (!_carregando && _erro == null)
              ..._itens.map((item) => Card(
                color: item['id'] == widget.registroDestaque
                  ? Theme.of(context).colorScheme.primaryContainer : null,
                child: Padding(padding: const EdgeInsets.all(8), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(c.icone, color: Theme.of(context).colorScheme.primary),
                    title: Text(_titulo(item), maxLines: 2),
                    subtitle: Text(c.campos.where((campo) => item[campo.chave] != null)
                        .map((campo) => '${campo.rotulo}: ${item[campo.chave]}').take(3).join('\n'),
                        maxLines: 4, overflow: TextOverflow.ellipsis),
                  ),
                  if (item['id'] == widget.registroDestaque)
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Registro selecionado a partir do aviso')),
                  if (item['estoque_baixo'] == true)
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Estoque baixo',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  if (c.recurso == 'alertas-panico') Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(item['resolvido'] == true ? 'Resolvido' : 'Pendente')),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (c.recurso == 'contatos-emergencia') ...[
                      IconButton(tooltip: 'Ligar para o contato', icon: const Icon(Icons.call_outlined),
                        onPressed: '${item['telefone'] ?? ''}'.isEmpty ? null
                          : () => AcoesExternas.telefone(context, '${item['telefone']}')),
                      IconButton(tooltip: 'Abrir WhatsApp do contato', icon: const Icon(Icons.chat_outlined),
                        onPressed: '${item['telefone'] ?? ''}'.isEmpty ? null
                          : () => AcoesExternas.whatsapp(context, '${item['telefone']}')),
                    ],
                    if (c.recurso == 'estoque') ...[
                      IconButton(tooltip: 'Diminuir quantidade', icon: const Icon(Icons.remove_circle_outline),
                        onPressed: ((item['quantidade'] as num?)?.toInt() ?? 0) > 0
                          ? () => _ajustarEstoque(item, -1) : null),
                      Text('${item['quantidade'] ?? 0}', semanticsLabel: 'Quantidade disponível'),
                      IconButton(tooltip: 'Aumentar quantidade', icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _ajustarEstoque(item, 1)),
                    ],
                    if (c.recurso == 'alertas-panico' && item['resolvido'] != true)
                      TextButton.icon(onPressed: () => _resolverAlerta(item),
                        icon: const Icon(Icons.check_circle_outline), label: const Text('Marcar resolvido')),
                    if (c.recurso == 'lesoes' && item['foto_url'] != null)
                      IconButton(tooltip: 'Visualizar foto da lesão', icon: const Icon(Icons.image_outlined),
                        onPressed: () async {
                          try {
                            final bytes = await _api.baixarArquivo('${item['foto_url']}');
                            if (!context.mounted) return;
                            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('Foto da lesão')),
                              body: Center(child: InteractiveViewer(child: Image.memory(bytes,
                                semanticLabel: 'Foto de lesão registrada no prontuário'))),
                            )));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e is ApiException ? e.message : 'Não foi possível abrir a foto.')));
                            }
                          }
                        }),
                    TextButton.icon(onPressed: () => _formulario(item), icon: const Icon(Icons.edit_outlined), label: const Text('Editar')),
                    TextButton.icon(onPressed: () => _excluir(item), icon: const Icon(Icons.delete_outline), label: const Text('Excluir')),
                  ]),
                ],
              )))),
            const SizedBox(height: 90),
          ]),
        ),
      )),
    );
  }
}

class _FormularioClinico extends StatefulWidget {
  const _FormularioClinico({required this.config, required this.api, this.atual});
  final ModuloClinicoConfig config;
  final ApiService api;
  final Map<String, dynamic>? atual;
  @override
  State<_FormularioClinico> createState() => _FormularioClinicoState();
}

class _FormularioClinicoState extends State<_FormularioClinico> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _inputs = {};
  bool _salvando = false;
  String? _erro;
  Uint8List? _fotoSelecionada;
  String? _fotoMime;
  bool _removerFoto = false;

  Future<void> _escolherFoto({required bool camera}) async {
    try {
      Uint8List? bytes;
      String nome = '';
      if (camera) {
        final imagem = await ImagePicker().pickImage(
            source: ImageSource.camera, imageQuality: 75, maxWidth: 1600);
        if (imagem == null) return;
        nome = imagem.name;
        bytes = await imagem.readAsBytes();
      } else {
        final arquivo = await FilePicker.platform.pickFiles(
            type: FileType.image, withData: true);
        if (arquivo == null) return;
        nome = arquivo.files.single.name;
        bytes = arquivo.files.single.bytes;
      }
      final extensao = nome.split('.').last.toLowerCase();
      final mime = switch (extensao) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (bytes == null || bytes.isEmpty || bytes.length > 5 * 1024 * 1024 ||
          mime == null) {
        throw ApiException('Escolha JPG, PNG ou WebP de até 5 MB.');
      }
      if (mounted) { setState(() {
        _fotoSelecionada = bytes;
        _fotoMime = mime;
        _removerFoto = false;
        _erro = null;
      });
      }
    } catch (e) {
      if (mounted) { setState(() => _erro = e is ApiException
          ? e.message : 'Não foi possível capturar ou selecionar a foto.');
      }
    }
  }


  @override
  void initState() {
    super.initState();
    for (final campo in widget.config.campos) {
      final valor = widget.atual?[campo.chave];
      _inputs[campo.chave] = TextEditingController(
        text: campo.chave == 'resolvido' && valor is bool
          ? (valor ? 'resolvido' : 'pendente')
          : valor is List ? valor.join(', ') : '${valor ?? ''}',
      );
      if (campo.tipo == TipoCampo.data && valor == null) {
        _inputs[campo.chave]!.text = DateTime.now().toIso8601String().substring(0, 19);
      }
      if (campo.tipo == TipoCampo.escolha && _inputs[campo.chave]!.text.isEmpty && campo.opcoes.isNotEmpty) {
        _inputs[campo.chave]!.text = campo.opcoes.first;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _inputs.values) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final dados = <String, dynamic>{};
    for (final campo in widget.config.campos) {
      final valor = _inputs[campo.chave]!.text.trim();
      if (valor.isEmpty && !campo.obrigatorio) continue;
      if (campo.tipo == TipoCampo.numero) {
        dados[campo.chave] = int.parse(valor);
      } else if (campo.tipo == TipoCampo.lista) {
        dados[campo.chave] = valor.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else if (widget.config.recurso == 'alertas-panico' && campo.chave == 'resolvido') {
        dados['resolvido'] = valor == 'resolvido';
      } else {
        dados[campo.chave] = valor;
      }
    }
    if (widget.config.recurso == 'lesoes') {
      if (_fotoSelecionada != null) {
        dados['foto_base64'] = base64Encode(_fotoSelecionada!);
        dados['foto_mime'] = _fotoMime;
      } else if (_removerFoto) {
        dados['foto_base64'] = null;
      }
    }
    // Um sinal vital requer pelo menos uma aferição, além da data.
    if (widget.config.recurso == 'sinais-vitais' &&
        !dados.keys.any((chave) => chave != 'data')) {
      setState(() => _erro = 'Informe pelo menos uma medição.');
      return;
    }
    setState(() { _salvando = true; _erro = null; });
    try {
      if (widget.atual == null) {
        await widget.api.criarRegistro(widget.config.recurso, dados);
      } else {
        await widget.api.atualizarRegistro(widget.config.recurso, widget.atual!['id'], dados);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Não foi possível salvar o registro.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.atual == null ? 'Novo registro' : 'Editar registro'),
    content: SizedBox(width: 460, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.config.campos.map((campo) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: campo.tipo == TipoCampo.escolha
              ? DropdownButtonFormField<String>(
                  initialValue: campo.opcoes.contains(_inputs[campo.chave]!.text)
                    ? _inputs[campo.chave]!.text : campo.opcoes.first,
                  decoration: InputDecoration(labelText: campo.rotulo, border: const OutlineInputBorder()),
                  items: campo.opcoes.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (novo) => _inputs[campo.chave]!.text = novo ?? '',
                )
              : TextFormField(
                  controller: _inputs[campo.chave],
                  keyboardType: campo.tipo == TipoCampo.numero ? TextInputType.number : TextInputType.text,
                  maxLines: campo.chave == 'descricao' || campo.chave == 'observacoes' ? 3 : 1,
                  decoration: InputDecoration(labelText: campo.rotulo,
                    helperText: campo.tipo == TipoCampo.data ? 'Formato: AAAA-MM-DDTHH:MM:SS' : null,
                    border: const OutlineInputBorder()),
                  validator: (v) {
                    final valor = (v ?? '').trim();
                    if (campo.obrigatorio && valor.isEmpty) return 'Campo obrigatório';
                    if (valor.isEmpty) return null;
                    if (campo.tipo == TipoCampo.numero && (int.tryParse(valor) == null || int.parse(valor) < 0)) {
                      return 'Digite um número inteiro não negativo';
                    }
                    if (campo.tipo == TipoCampo.data && DateTime.tryParse(valor) == null) return 'Data/hora inválida';
                    return null;
                  },
                ),
        )),
        if (widget.config.recurso == 'lesoes') ...[
          const SizedBox(height: 8),
          const Text('Fotografia da lesão (opcional). Evite registrar informações desnecessárias na imagem.'),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(onPressed: _salvando ? null : () => _escolherFoto(camera: false),
              icon: const Icon(Icons.image_outlined), label: const Text('Galeria / arquivo')),
            OutlinedButton.icon(onPressed: _salvando ? null : () => _escolherFoto(camera: true),
              icon: const Icon(Icons.camera_alt_outlined), label: const Text('Câmera')),
            if (_fotoSelecionada != null || widget.atual?['foto_url'] != null)
              TextButton.icon(onPressed: _salvando ? null : () => setState(() {
                _fotoSelecionada = null; _fotoMime = null; _removerFoto = true;
              }), icon: const Icon(Icons.delete_outline), label: const Text('Remover foto')),
          ]),
          if (_fotoSelecionada != null) Padding(padding: const EdgeInsets.only(top: 8),
              child: Image.memory(_fotoSelecionada!, height: 128, fit: BoxFit.contain,
                  semanticLabel: 'Foto selecionada para anexar ao registro')),
          if (widget.atual?['foto_url'] != null && _fotoSelecionada == null && !_removerFoto)
              const Text('O registro já possui uma foto. Selecione outra para substituir.'),
        ],
        if (_erro != null) Padding(padding: const EdgeInsets.all(8), child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ],
    )))),
    actions: [
      TextButton(onPressed: _salvando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
      FilledButton(onPressed: _salvando ? null : _salvar,
        child: Text(_salvando ? 'Salvando...' : 'Salvar')),
    ],
  );
}

/// Histórico simples com uma escala por vez. Não mistura unidades diferentes.
class _GraficoSinais extends StatefulWidget {
  const _GraficoSinais({required this.itens});
  final List<Map<String, dynamic>> itens;
  @override
  State<_GraficoSinais> createState() => _GraficoSinaisState();
}

class _GraficoSinaisState extends State<_GraficoSinais> {
  String _campo = 'freq_cardiaca';
  DateTimeRange? _intervalo;
  Map<String, dynamic>? _series;
  String? _erroEvolucao;

  @override
  void initState() {
    super.initState();
    _atualizarEvolucao();
  }
  @override
  void didUpdateWidget(covariant _GraficoSinais oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itens != widget.itens) _atualizarEvolucao();
  }

  Future<void> _atualizarEvolucao() async {
    try {
      // The series endpoint uses the patient selected in the current session.
      final response = await ApiService().requisicao('GET',
        '/pacientes/${SessionService.instance.pacienteId}/sinais-vitais/evolucao');
      if (mounted && response is Map) setState(() => _series = Map<String, dynamic>.from(response));
    } catch (e) {
      if (mounted) setState(() => _erroEvolucao = e is ApiException ? e.message : 'Não foi possível atualizar a evolução.');
    }
  }

  static const campos = {
    'freq_cardiaca': 'Frequência cardíaca (bpm)',
    'temperatura': 'Temperatura (°C)',
    'saturacao': 'Saturação (%)',
    'glicemia': 'Glicemia (unidade informada)',
  };
  @override
  Widget build(BuildContext context) {
    final ordenados = [...widget.itens]..sort((a,b) => '${a['data']}'.compareTo('${b['data']}'));
    final labels = (_series?['labels'] as List?) ?? const [];
    final origem = (_series?['series'] is Map) ? _series!['series'] as Map : const {};
    final valores = origem[_campo] is List ? origem[_campo] as List : const [];
    final pontos = <double>[];
    if (labels.length == valores.length && labels.isNotEmpty) {
      for (var i = 0; i < labels.length; i++) {
        final data = DateTime.tryParse('${labels[i]}');
        if (_intervalo != null && (data == null ||
            data.isBefore(DateTime(_intervalo!.start.year, _intervalo!.start.month, _intervalo!.start.day)) ||
            !data.isBefore(DateTime(_intervalo!.end.year, _intervalo!.end.month, _intervalo!.end.day + 1)))) {
          continue;
        }
        final valor = double.tryParse('${valores[i] ?? ''}'.replaceAll(',', '.'));
        if (valor != null && valor.isFinite) pontos.add(valor);
      }
    } else {
      for (final item in ordenados) {
        final data = DateTime.tryParse('${item['data'] ?? ''}');
        if (_intervalo != null && (data == null ||
            data.isBefore(_intervalo!.start) ||
            !data.isBefore(DateTime(_intervalo!.end.year, _intervalo!.end.month, _intervalo!.end.day + 1)))) {
          continue;
        }
        final v = double.tryParse('${item[_campo] ?? ''}'.replaceAll(',', '.'));
        if (v != null && v.isFinite) pontos.add(v);
      }
    }
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Evolução das medições', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButton<String>(isExpanded: true, value: _campo,
          items: campos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) { if (v != null) setState(() => _campo = v); }),
        Wrap(spacing: 8, children: [
          TextButton.icon(onPressed: () async {
            final intervalo = await showDateRangePicker(context: context,
              firstDate: DateTime(2000), lastDate: DateTime(2100), initialDateRange: _intervalo);
            if (intervalo != null && mounted) setState(() => _intervalo = intervalo);
          }, icon: const Icon(Icons.date_range),
            label: Text(_intervalo == null ? 'Filtrar período' : 'Período selecionado')),
          if (_intervalo != null) TextButton(onPressed: () => setState(() => _intervalo = null),
            child: const Text('Limpar filtro')),
          IconButton(onPressed: _atualizarEvolucao, icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar evolução'),
        ]),
        if (_erroEvolucao != null) Text(_erroEvolucao!),
        if (pontos.length < 2) const Text('Cadastre pelo menos duas medidas numéricas para visualizar a evolução.'),
        if (pontos.length >= 2) SizedBox(height: 160, width: double.infinity,
          child: CustomPaint(painter: _PintorGrafico(pontos, Theme.of(context).colorScheme.primary))),
        const SizedBox(height: 8),
        const Text('Gráfico de valores informados, sem interpretação clínica.', style: TextStyle(fontSize: 12)),
      ],
    )));
  }
}

class _PintorGrafico extends CustomPainter {
  const _PintorGrafico(this.valores, this.cor);
  final List<double> valores;
  final Color cor;
  @override
  void paint(Canvas canvas, Size size) {
    final minY = valores.reduce(math.min);
    final maxY = valores.reduce(math.max);
    final alcance = math.max(maxY - minY, 1.0);
    final eixo = Paint()..color = const Color(0xFFB8C4D2)..strokeWidth = 1;
    canvas.drawLine(Offset(8, size.height - 10), Offset(size.width - 8, size.height - 10), eixo);
    final linha = Path();
    for (var i = 0; i < valores.length; i++) {
      final x = 10.0 + i * (size.width - 20) / (valores.length - 1);
      final y = size.height - 15 - (valores[i] - minY) / alcance * (size.height - 30);
      if (i == 0) { linha.moveTo(x, y); } else { linha.lineTo(x, y); }
      canvas.drawCircle(Offset(x,y), 3, Paint()..color = cor);
    }
    final pincel = Paint();
    pincel.color = cor;
    pincel.strokeWidth = 2.5;
    pincel.style = PaintingStyle.stroke;
    canvas.drawPath(linha, pincel);
  }
  @override
  bool shouldRepaint(covariant _PintorGrafico old) => old.cor != cor || old.valores != valores;
}
