import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';

class RelatoriosPdf extends StatefulWidget {
  const RelatoriosPdf({super.key});
  @override
  State<RelatoriosPdf> createState() => _RelatoriosPdfState();
}

class _RelatoriosPdfState extends State<RelatoriosPdf> {
  DateTime periodo = DateTime.now();
  final _email = TextEditingController();
  bool ocupado = false;
  String? mensagem;

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> baixar() async {
    setState(() { ocupado = true; mensagem = null; });
    try {
      final bytes = await ApiService().baixarRelatorio(periodo.year, periodo.month);
      await Printing.sharePdf(bytes: bytes,
        filename: 'relatorio-${periodo.year}-${periodo.month.toString().padLeft(2,'0')}.pdf');
    } catch (e) {
      if (mounted) setState(() => mensagem = e is ApiException ? e.message : 'Erro ao gerar PDF.');
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> enviar() async {
    final destinatario = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(destinatario)) {
      setState(() => mensagem = 'Informe um e-mail válido.');
      return;
    }
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Enviar relatório?'),
      content: Text('O relatório pode conter dados sensíveis de saúde. Confirme que ${_email.text.trim()} está autorizado a recebê-lo.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar'))],
    ));
    if (confirmar != true) return;
    setState(() { ocupado = true; mensagem = null; });
    try {
      await ApiService().requisicao('POST', '/pacientes/${SessionService.instance.pacienteId}/historico/email', dados: {
        'email': destinatario,
        'ano': periodo.year,
        'mes': periodo.month,
      });
      if (mounted) setState(() => mensagem = 'Solicitação de envio aceita pela API.');
    } catch (e) {
      if (mounted) setState(() => mensagem = e is ApiException ? e.message : 'Falha ao enviar relatório.');
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Relatórios em PDF')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 650),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Icon(Icons.picture_as_pdf_outlined, size: 66, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Histórico mensal', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        const Text('Dados obtidos do paciente selecionado. Não compartilhe sem autorização.'),
        const SizedBox(height: 12),
        ListTile(title: const Text('Mês do relatório'),
          subtitle: Text('${periodo.month.toString().padLeft(2, '0')}/${periodo.year}'),
          trailing: const Icon(Icons.calendar_month), onTap: ocupado ? null : () async {
            final data = await showDatePicker(context: context, initialDate: periodo,
              firstDate: DateTime(2000), lastDate: DateTime.now());
            if (data != null && mounted) setState(() => periodo = data);
          }),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: ocupado ? null : baixar,
          icon: const Icon(Icons.download), label: const Text('Baixar / compartilhar PDF')),
        const SizedBox(height: 24),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail do destinatário autorizado',
            border: OutlineInputBorder())),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: ocupado ? null : enviar,
          icon: const Icon(Icons.mail_outline), label: const Text('Enviar relatório por e-mail')),
        if (ocupado) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
        if (mensagem != null) Padding(padding: const EdgeInsets.all(12), child: Text(mensagem!)),
      ]))),
  );
}
