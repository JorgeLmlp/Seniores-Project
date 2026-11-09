import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class EvolucaoVital extends StatefulWidget {
  const EvolucaoVital({super.key, required this.api, required this.pacienteId});
  final ApiService api;
  final int pacienteId;
  @override
  State<EvolucaoVital> createState() => _EvolucaoVitalState();
}

class _EvolucaoVitalState extends State<EvolucaoVital> {
  late Future<dynamic> _dados = _carregar();
  String _medida = 'temperatura';
  static const _medidas = {
    'temperatura': 'Temperatura (°C)',
    'glicemia': 'Glicemia (mg/dL)',
    'freq_cardiaca': 'Frequência cardíaca (bpm)',
    'saturacao': 'Saturação (%)',
    'pressao_art': 'Pressão arterial (mmHg)'
  };
  Future<dynamic> _carregar() => widget.api.requisicao(
      'GET', '/pacientes/${widget.pacienteId}/sinais-vitais/evolucao');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Evolução dos sinais vitais')),
        body: FutureBuilder<dynamic>(
            future: _dados,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                    child: TextButton(
                        onPressed: () => setState(() => _dados = _carregar()),
                        child: const Text(
                            'Não foi possível carregar. Tentar novamente')));
              }
              final labels = (snap.data['labels'] as List?) ?? [];
              final series = (snap.data['series'] as Map?) ?? {};
              final valores = (series[_medida] as List?) ?? [];
              final linhas = <LineChartBarData>[];
              for (var parte = 0;
                  parte < (_medida == 'pressao_art' ? 2 : 1);
                  parte++) {
                final pontos = <FlSpot>[];
                for (var i = 0; i < valores.length; i++) {
                  final partes =
                      valores[i]?.toString().replaceAll(',', '.').split('/') ??
                          [];
                  final valor = partes.length > parte
                      ? double.tryParse(partes[parte])
                      : null;
                  if (valor != null && valor.isFinite) {
                    pontos.add(FlSpot(i.toDouble(), valor));
                  }
                }
                if (pontos.isNotEmpty) {
                  linhas.add(LineChartBarData(
                      spots: pontos,
                      color: parte == 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.orange,
                      isCurved: false,
                      barWidth: 3,
                      dotData: const FlDotData(show: true)));
                }
              }
              String data(int i) {
                if (i < 0 || i >= labels.length) return '';
                final d = DateTime.tryParse(labels[i].toString());
                return d == null
                    ? labels[i].toString()
                    : DateFormat('dd/MM/yyyy HH:mm').format(d);
              }

              return Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            DropdownButtonFormField<String>(
                                initialValue: _medida,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Medição',
                                    border: OutlineInputBorder()),
                                items: _medidas.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.key, child: Text(e.value)))
                                    .toList(),
                                onChanged: (v) => setState(() => _medida = v!)),
                            const SizedBox(height: 24),
                            if (linhas.isEmpty)
                              const Text(
                                  'Não há medições deste sinal no período registrado.')
                            else ...[
                              if (_medida == 'pressao_art')
                                const Text(
                                    'Azul: sistólica • Laranja: diastólica'),
                              const SizedBox(height: 16),
                              SizedBox(
                                  height: 280,
                                  child: LineChart(LineChartData(
                                    lineBarsData: linhas,
                                    borderData: FlBorderData(show: false),
                                    titlesData: const FlTitlesData(
                                        topTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 48))),
                                  ))),
                              const SizedBox(height: 16),
                              const Text(
                                  'Medições na ordem retornada pelo histórico. Os valores completos estão abaixo.'),
                              for (var i = 0; i < valores.length; i++)
                                if (valores[i] != null)
                                  ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(data(i)),
                                      subtitle: Text('${valores[i]}')),
                            ],
                          ])));
            }),
      );
}
