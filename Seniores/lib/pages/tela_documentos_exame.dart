import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/documento_exame.dart';
import '../models/exames.dart';
import '../services/api_service.dart';

class DocumentosExame extends StatefulWidget {
  final Exame exame;

  const DocumentosExame({super.key, required this.exame});

  @override
  State<DocumentosExame> createState() => _DocumentosExameState();
}

class _DocumentosExameState extends State<DocumentosExame> {
  final _api = ApiService();
  List<DocumentoExame> _documentos = [];
  bool _carregando = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (widget.exame.id == null) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final documentos = await _api.listarDocumentosExame(widget.exame.id!);
      if (!mounted) return;
      setState(() {
        _documentos = documentos;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar os documentos.');
    }
  }

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (resultado == null || !mounted) return;
    final arquivo = resultado.files.single;
    final bytes = arquivo.bytes;
    if (bytes == null || bytes.isEmpty) {
      _mostrarMensagem('Não foi possível ler o arquivo selecionado.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final documento = await _api.enviarDocumentoExame(
        exameId: widget.exame.id!,
        nome: arquivo.name,
        bytes: bytes,
      );
      if (mounted) setState(() => _documentos = [documento, ..._documentos]);
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _capturarCamera() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (arquivo == null || !mounted) return;
    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) {
      _mostrarMensagem('Não foi possível ler a imagem capturada.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final documento = await _api.enviarDocumentoExame(
        exameId: widget.exame.id!,
        nome: 'captura_${DateTime.now().millisecondsSinceEpoch}.jpg',
        bytes: bytes,
      );
      if (mounted) setState(() => _documentos = [documento, ..._documentos]);
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrir(DocumentoExame documento) async {
    final abriu = await launchUrl(
      Uri.parse(
        '${ApiService.baseUrl}/documentos-exame/${documento.id}/arquivo',
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) _mostrarMensagem('Não foi possível abrir o documento.');
  }

  Future<void> _excluir(DocumentoExame documento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir documento?'),
        content: Text(documento.nome),
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
      await _api.deletarDocumentoExame(documento.id);
      if (mounted) {
        setState(
          () => _documentos.removeWhere((item) => item.id == documento.id),
        );
      }
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
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
      appBar: AppBar(
        title: Text('Documentos — ${widget.exame.nome}'),
        actions: [
          IconButton(
            tooltip: 'Capturar com câmera',
            onPressed: _enviando ? null : _capturarCamera,
            icon: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _documentos.isEmpty
          ? const Center(child: Text('Nenhum documento enviado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _documentos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final documento = _documentos[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(documento.nome),
                    subtitle: Text(
                      '${documento.mimeType} • ${documento.tamanho} bytes',
                    ),
                    onTap: () => _abrir(documento),
                    trailing: IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _excluir(documento),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviando ? null : _selecionarArquivo,
        child: _enviando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.upload_file),
      ),
    );
  }
}
