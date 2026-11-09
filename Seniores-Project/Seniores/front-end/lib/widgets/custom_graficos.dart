import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class GraficoEstatisticas extends StatefulWidget {
  const GraficoEstatisticas({super.key});
  @override
  State<GraficoEstatisticas> createState() => _GraficoEstatisticasState();
}

class _GraficoEstatisticasState extends State<GraficoEstatisticas> {
  late Future<List<Map<String, dynamic>>> registros;
  @override
  void initState() {
    super.initState();
    registros = ApiService().listarDiarios();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<
          List<Map<String, dynamic>>>(
      future: registros,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
              child: TextButton(
                  onPressed: () =>
                      setState(() => registros = ApiService().listarDiarios()),
                  child: const Text('Falha ao carregar. Tentar novamente')));
        }
        final dados = [...snap.data!]..sort((a, b) => (a['data_criacao'] ?? '')
            .toString()
            .compareTo((b['data_criacao'] ?? '').toString()));
        if (dados.isEmpty) {
          return const Center(
              child: Text('Registre um diário para visualizar o gráfico.'));
        }
        const campos = {
          'humor_nivel': 'Humor',
          'dor_nivel': 'Dor',
          'apetite_nivel': 'Apetite',
          'mobilidade_nivel': 'Mobilidade'
        };
        const cores = [Colors.blue, Colors.orange, Colors.green, Colors.purple];
        final linhas = <LineChartBarData>[];
        var indice = 0;
        for (final campo in campos.keys) {
          final pontos = <FlSpot>[];
          for (var i = 0; i < dados.length; i++) {
            final valor = dados[i][campo];
            if (valor is num) {
              pontos.add(FlSpot(i.toDouble(), valor.toDouble()));
            }
          }
          linhas.add(LineChartBarData(
              spots: pontos,
              color: cores[indice++],
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: true)));
        }
        if (linhas.every((l) => l.spots.isEmpty)) {
          return const Center(
              child: Text(
                  'Os registros antigos não possuem níveis numéricos. Adicione um novo diário.'));
        }
        return Column(children: [
          Expanded(
              child: LineChart(LineChartData(
            minY: 0,
            maxY: 10,
            minX: 0,
            maxX: dados.length == 1 ? 1 : (dados.length - 1).toDouble(),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: linhas,
            lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                          final raw =
                              dados[s.x.toInt()]['data_criacao']?.toString() ??
                                  '';
                          final date = DateTime.tryParse(raw);
                          final label = date == null
                              ? raw
                              : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                          return LineTooltipItem(
                              '$label\n${campos.values.elementAt(s.barIndex)}: ${s.y}',
                              const TextStyle(color: Colors.white));
                        }).toList())),
          ))),
          const SizedBox(height: 12),
          Wrap(spacing: 12, children: [
            for (var i = 0; i < campos.length; i++)
              Text(campos.values.elementAt(i),
                  style: TextStyle(color: cores[i]))
          ])
        ]);
      });
}
