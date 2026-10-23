import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/registroDiario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Relatorios extends StatefulWidget {
  const Relatorios({super.key});

  @override
  State<Relatorios> createState() => _RelatoriosState();
}

class _RelatoriosState extends State<Relatorios> {
  final _email = TextEditingController();
  bool _enviando = false;
  bool _gerandoPdf = false;
  String? _mensagem;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _erro = 'Informe um e-mail válido.';
        _mensagem = null;
      });
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
      _mensagem = null;
    });
    try {
      final resposta = await ApiService().enviarRelatorioEmail(email);
      if (mounted) setState(() => _mensagem = resposta);
    } on ApiException catch (exception) {
      if (mounted) setState(() => _erro = exception.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<Uint8List> _gerarPdf() async {
    final registros = await ApiService().listarRegistrosDiarios(
      SessionService.instance.pacienteId,
    );
    final documento = pw.Document();
    final dataGeracao = DateTime.now().toIso8601String().split('T').first;

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (_) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text(
            'Seniores — Relatório de saúde',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${context.pageNumber}'),
        ),
        build: (_) => [
          pw.Text('Gerado em: $dataGeracao'),
          pw.SizedBox(height: 16),
          pw.Text(
            registros.isEmpty
                ? 'Nenhum registro diário encontrado.'
                : 'Registros do diário (${registros.length})',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (registros.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: const [
                'Data',
                'Humor',
                'Dor',
                'Apetite',
                'Mobilidade',
                'Incidentes',
              ],
              data: registros.map(_linhaPdf).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
          pw.SizedBox(height: 18),
          ...registros
              .where((registro) =>
                  registro.observacoes.trim().isNotEmpty ||
                  registro.duvidas.trim().isNotEmpty)
              .map(
                (registro) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    '${_formatarData(registro)} — '
                    'Observações: ${registro.observacoes.trim().isEmpty ? '-' : registro.observacoes.trim()} '
                    'Dúvidas: ${registro.duvidas.trim().isEmpty ? '-' : registro.duvidas.trim()}',
                  ),
                ),
              ),
        ],
      ),
    );
    return documento.save();
  }

  List<String> _linhaPdf(RegistroModel registro) => [
    _formatarData(registro),
    registro.humor.toStringAsFixed(1),
    registro.dor.toStringAsFixed(1),
    registro.apetite.toStringAsFixed(1),
    registro.mobilidade.toStringAsFixed(1),
    registro.totalIncidentes.toString(),
  ];

  String _formatarData(RegistroModel registro) =>
      registro.data?.toIso8601String().split('T').first ?? 'Sem data';

  Future<void> _visualizarPdf() async {
    await _executarPdf((bytes) async {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    });
  }

  Future<void> _compartilharPdf() async {
    await _executarPdf((bytes) async {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'relatorio-saude-seniores.pdf',
      );
    });
  }

  Future<void> _executarPdf(Future<void> Function(Uint8List) acao) async {
    setState(() {
      _gerandoPdf = true;
      _erro = null;
    });
    try {
      final bytes = await _gerarPdf();
      await acao(bytes);
    } on ApiException catch (exception) {
      if (mounted) setState(() => _erro = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível gerar o PDF.');
      }
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.description_outlined, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Envie o resumo do histórico diário por e-mail.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          CampoTexto(
            hintText: 'E-mail de destino',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          const SizedBox(height: 16),
          Botao(
            texto: _enviando ? 'Enviando relatório...' : 'Enviar por e-mail',
            onPressed: _enviando ? () {} : _enviar,
          ),
          if (_enviando) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(),
          ],
          if (_mensagem != null) ...[
            const SizedBox(height: 18),
            Text(_mensagem!, style: const TextStyle(color: Colors.green)),
          ],
          if (_erro != null) ...[
            const SizedBox(height: 18),
            Text(_erro!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Exportar histórico',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _gerandoPdf ? null : _visualizarPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              _gerandoPdf ? 'Gerando PDF...' : 'Visualizar / baixar PDF',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _gerandoPdf ? null : _compartilharPdf,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartilhar PDF'),
          ),
          const SizedBox(height: 24),
          const Text(
            'O envio por e-mail depende da configuração SMTP da API. O PDF é gerado localmente com os registros do diário carregados da API.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
