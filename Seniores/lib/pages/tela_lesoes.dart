import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/lesao.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Lesoes extends StatefulWidget {
  const Lesoes({super.key});

  @override
  State<Lesoes> createState() => _LesoesState();
}

class _LesoesState extends State<Lesoes> {
  final _api = ApiService();
  List<Lesao> _lesoes = [];
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
      final lesoes = await _api.listarLesoes(SessionService.instance.pacienteId);
      if (!mounted) return;
      setState(() {
        _lesoes = lesoes;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar as lesões.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirFormulario([Lesao? lesao]) async {
    final resultado = await showDialog<Lesao>(
      context: context,
      builder: (_) => FormularioLesao(lesao: lesao),
    );
    if (resultado == null || !mounted) return;
    try {
      var salvo = resultado.id == null
          ? await _api.criarLesao(SessionService.instance.pacienteId, resultado)
          : await _api.atualizarLesao(resultado);
      if (resultado.fotoBytes != null && resultado.fotoNome != null) {
        salvo = await _api.enviarFotoLesao(
          lesaoId: salvo.id!,
          nome: resultado.fotoNome!,
          bytes: resultado.fotoBytes!,
        );
      }
      if (!mounted) return;
      setState(() {
        final indice = _lesoes.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _lesoes = [salvo, ..._lesoes];
        } else {
          _lesoes[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar a lesão.');
    }
  }

  Future<void> _excluir(Lesao lesao) async {
    if (lesao.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lesão?'),
        content: const Text('O prontuário será removido do histórico.'),
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
    if (confirmar != true || !mounted) return;
    try {
      await _api.deletarLesao(lesao.id!);
      if (mounted) setState(() => _lesoes.removeWhere((item) => item.id == lesao.id));
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  Future<void> _abrirFoto(Lesao lesao) async {
    if (lesao.id == null) return;
    final abriu = await launchUrl(
      Uri.parse('${ApiService.baseUrl}/lesoes/${lesao.id}/foto'),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) _mostrarMensagem('Não foi possível abrir a foto.');
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prontuário de lesões')),
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
            : _lesoes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Nenhuma lesão registrada.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _lesoes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final lesao = _lesoes[index];
                  return Card(
                    child: ListTile(
                      leading: IconButton(
                        tooltip: lesao.fotoNome == null
                            ? 'Sem foto'
                            : 'Abrir foto',
                        icon: Icon(
                          lesao.fotoNome == null
                              ? Icons.photo_camera_outlined
                              : Icons.photo,
                        ),
                        onPressed: lesao.fotoNome == null
                            ? null
                            : () => _abrirFoto(lesao),
                      ),
                      title: Text(lesao.localizacao),
                      subtitle: Text(
                        '${lesao.dataInicio}\n${lesao.descricao}'
                        '${lesao.evolucao.isEmpty ? '' : '\nEvolução: ${lesao.evolucao}'}',
                      ),
                      isThreeLine: lesao.evolucao.isNotEmpty,
                      onTap: () => _abrirFormulario(lesao),
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _excluir(lesao),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FormularioLesao extends StatefulWidget {
  final Lesao? lesao;

  const FormularioLesao({super.key, this.lesao});

  @override
  State<FormularioLesao> createState() => _FormularioLesaoState();
}

class _FormularioLesaoState extends State<FormularioLesao> {
  late final TextEditingController _localizacao;
  late final TextEditingController _dataInicio;
  late final TextEditingController _descricao;
  late final TextEditingController _evolucao;
  String? _fotoNome;
  List<int>? _fotoBytes;

  @override
  void initState() {
    super.initState();
    final lesao = widget.lesao;
    _localizacao = TextEditingController(text: lesao?.localizacao);
    _dataInicio = TextEditingController(
      text: lesao?.dataInicio ?? _dataAtual(),
    );
    _descricao = TextEditingController(text: lesao?.descricao);
    _evolucao = TextEditingController(text: lesao?.evolucao);
  }

  String _dataAtual() {
    final agora = DateTime.now();
    return '${agora.year.toString().padLeft(4, '0')}-'
        '${agora.month.toString().padLeft(2, '0')}-'
        '${agora.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _localizacao.dispose();
    _dataInicio.dispose();
    _descricao.dispose();
    _evolucao.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (resultado == null || !mounted) return;
    final arquivo = resultado.files.single;
    if (arquivo.bytes == null || arquivo.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler a imagem.')),
      );
      return;
    }
    setState(() {
      _fotoNome = arquivo.name;
      _fotoBytes = arquivo.bytes;
    });
  }

  Future<void> _capturarFoto() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (arquivo == null || !mounted) return;
    final bytes = await arquivo.readAsBytes();
    setState(() {
      _fotoNome = 'lesao_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _fotoBytes = bytes;
    });
  }

  void _salvar() {
    if (_localizacao.text.trim().isEmpty ||
        _dataInicio.text.trim().isEmpty ||
        _descricao.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localização, data de início e descrição são obrigatórias.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Lesao(
        id: widget.lesao?.id,
        localizacao: _localizacao.text.trim(),
        dataInicio: _dataInicio.text.trim(),
        descricao: _descricao.text.trim(),
        evolucao: _evolucao.text.trim(),
        fotoNome: _fotoNome,
        fotoBytes: _fotoBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lesao == null ? 'Nova lesão' : 'Editar lesão'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampoTexto(hintText: 'Localização', controller: _localizacao),
              const SizedBox(height: 10),
              CampoTexto(hintText: 'Data de início', controller: _dataInicio),
              const SizedBox(height: 10),
              CampoTexto(hintText: 'Descrição', controller: _descricao),
              const SizedBox(height: 10),
              CampoTexto(hintText: 'Evolução', controller: _evolucao),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selecionarArquivo,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Selecionar foto'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Capturar foto',
                    onPressed: _capturarFoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
              if (_fotoNome != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Foto: $_fotoNome'),
                ),
              ],
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
