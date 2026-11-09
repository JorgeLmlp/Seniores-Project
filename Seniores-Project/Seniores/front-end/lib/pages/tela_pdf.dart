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
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> enviar() async {
    if (!form.currentState!.validate()) return;
    setState(() => ocupado = true);
    try {
      final id = SessionService.instance.pacienteId;
      await ApiService().requisicao('POST', '/pacientes/$id/historico/email',
          dados: {
            'email': email.text.trim(),
            'mes': periodo.month,
            'ano': periodo.year
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Envio do relatório aceito.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível enviar o relatório.')));
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  DateTime periodo = DateTime.now();
  bool ocupado = false;
  Future<void> baixar() async {
    setState(() => ocupado = true);
    try {
      final bytes =
          await ApiService().baixarRelatorio(periodo.year, periodo.month);
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              'relatorio-${periodo.year}-${periodo.month.toString().padLeft(2, '0')}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível baixar o relatório. Verifique a conexão.')));
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Relatórios em PDF')),
      body: ListView(padding: EdgeInsets.all(24), children: [
        Icon(Icons.picture_as_pdf_outlined,
            size: 64, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 20),
        Text('Histórico mensal de cuidados',
            style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 12),
        Text(
            'Selecione o período para baixar o relatório gerado pela API com os registros do paciente ativo.'),
        SizedBox(height: 24),
        ListTile(
            title: Text('Período'),
            subtitle: Text(
                '${periodo.month.toString().padLeft(2, '0')}/${periodo.year}'),
            trailing: Icon(Icons.calendar_month),
            onTap: ocupado
                ? null
                : () async {
                    final data = await showDatePicker(
                        context: context,
                        initialDate: periodo,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now());
                    if (data != null && mounted) setState(() => periodo = data);
                  }),
        SizedBox(height: 24),
        FilledButton.icon(
            onPressed: ocupado ? null : baixar,
            icon: Icon(Icons.download),
            label: Text(ocupado ? 'Gerando PDF...' : 'Baixar PDF')),
        const SizedBox(height: 24),
        Form(
            key: form,
            child: TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'E-mail do destinatário',
                    border: OutlineInputBorder()),
                validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Informe um e-mail válido.')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: ocupado ? null : enviar,
            icon: const Icon(Icons.email_outlined),
            label: const Text('Enviar relatório por e-mail')),
      ]));
}
