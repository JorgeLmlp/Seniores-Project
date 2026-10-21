import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class RelatoriosPdf extends StatefulWidget {
  const RelatoriosPdf({super.key});
  @override
  State<RelatoriosPdf> createState() => _RelatoriosPdfState();
}

class _RelatoriosPdfState extends State<RelatoriosPdf> {
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível baixar o relatório. Verifique a conexão.')));
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
      ]));
}
