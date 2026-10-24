import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/api_service.dart';

class DocumentosExames extends StatefulWidget {
  const DocumentosExames({super.key});
  @override
  State<DocumentosExames> createState() => _DocumentosExamesState();
}

class _DocumentosExamesState extends State<DocumentosExames> {
  final ApiService _api = ApiService();
  final _nome = TextEditingController();
  List<Map<String, dynamic>> _arquivos = [];
  bool _carregando = false;
  String? _erro;
  @override
  void initState() { super.initState(); _listar(); }
  @override
  void dispose() { _nome.dispose(); super.dispose(); }

  Future<void> _listar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final dados = await _api.listarRegistros('exames-documentos');
      if (mounted) setState(() => _arquivos = dados);
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Não foi possível listar os arquivos.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do exame.')));
      return;
    }
    try {
      final resultado = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'], withData: true);
      if (resultado == null) return;
      final arquivo = resultado.files.single;
      final bytes = arquivo.bytes;
      if (bytes == null || bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw ApiException('Escolha arquivo válido de até 10 MB.');
      }
      final ext = arquivo.extension?.toLowerCase();
      final mime = switch (ext) {
        'pdf' => 'application/pdf', 'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg', 'webp' => 'image/webp',
        _ => null,
      };
      if (mime == null) throw ApiException('Formato não permitido.');
      if (mounted) setState(() => _carregando = true);
      await _api.enviarDocumentoExame(nome: _nome.text.trim(),
        nomeArquivo: arquivo.name, conteudo: bytes, mime: mime);
      if (mounted) { _nome.clear(); await _listar(); }
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Não foi possível anexar.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _capturarFoto() async {
    if (_nome.text.trim().isEmpty) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe o nome do exame antes de fotografar.')));
      }
      return;
    }
    try {
      final foto = await ImagePicker().pickImage(source: ImageSource.camera,
          imageQuality: 80, maxWidth: 1800);
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw ApiException('Foto inválida ou maior que 10 MB.');
      }
      if (mounted) setState(() { _carregando = true; _erro = null; });
      await _api.enviarDocumentoExame(nome: _nome.text.trim(),
          nomeArquivo: 'exame-${DateTime.now().millisecondsSinceEpoch}.jpg',
          conteudo: bytes, mime: 'image/jpeg');
      if (mounted) { _nome.clear(); await _listar(); }
    } catch (e) {
      if (mounted) { setState(() => _erro = e is ApiException
          ? e.message : 'Falha ao fotografar documento.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(Map<String, dynamic> item) async {
    try {
      final bytes = await _api.baixarArquivo('${item['arquivo_url']}');
      if (!mounted) return;
      final mime = '${item['mime_type'] ?? ''}';
      if (mime == 'application/pdf') {
        await Printing.sharePdf(bytes: bytes,
          filename: '${item['nome_arquivo'] ?? 'exame.pdf'}');
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: Text('${item['nome'] ?? 'Documento'}')),
          body: Center(child: InteractiveViewer(child: Image.memory(bytes)))),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Erro ao abrir documento.')));
    }
  }

  Future<void> _excluir(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir documento?'),
      content: Text('${item['nome_arquivo'] ?? ''}'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir'))],
    ));
    if (ok != true) return;
    try {
      await _api.excluirRegistro('exames-documentos', item['id']);
      await _listar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Erro ao excluir.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Documentos de exames')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
      child: RefreshIndicator(onRefresh: _listar, child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Anexe arquivos PDF ou imagens de até 10 MB. O envio depende da API e da sua autorização de acesso.'),
        const SizedBox(height: 16),
        TextField(controller: _nome, decoration: const InputDecoration(
          labelText: 'Nome do exame', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _carregando ? null : _enviar,
          icon: const Icon(Icons.file_upload_outlined), label: const Text('Escolher e enviar arquivo')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _carregando ? null : _capturarFoto,
          icon: const Icon(Icons.camera_alt_outlined), label: const Text('Fotografar documento')),
        const Text('A fotografia não aplica recorte ou escaneamento automático.'),
        if (_carregando) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (_erro != null) Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 18),
        if (_arquivos.isEmpty && !_carregando) const Text('Nenhum documento encontrado.'),
        ..._arquivos.map((doc) => Card(child: ListTile(
          title: Text('${doc['nome'] ?? 'Exame'}'),
          subtitle: Text('${doc['nome_arquivo'] ?? ''}'),
          leading: const Icon(Icons.picture_as_pdf_outlined),
          onTap: () => _abrir(doc),
          trailing: IconButton(tooltip: 'Excluir', onPressed: () => _excluir(doc), icon: const Icon(Icons.delete_outline)),
        ))),
      ])))),
  );
}
