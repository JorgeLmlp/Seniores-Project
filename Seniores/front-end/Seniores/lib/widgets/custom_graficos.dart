import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/cores.dart';

class GraficoEstatisticas extends StatelessWidget {
  const GraficoEstatisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _criarLinha([
            const FlSpot(0, 1),
            const FlSpot(1, 1.5),
            const FlSpot(2, 1.2),
            const FlSpot(3, 3.5),
            const FlSpot(4, 2),
            const FlSpot(5, 1),
            const FlSpot(6, 2.5),
          ], Cores.azul),
          _criarLinha([
            const FlSpot(0, 2.5),
            const FlSpot(1, 3),
            const FlSpot(2, 2),
            const FlSpot(3, 1),
            const FlSpot(4, 0.5),
            const FlSpot(5, 2.5),
            const FlSpot(6, 3.8),
          ], Cores.verde),
          _criarLinha([
            const FlSpot(0, 1.5),
            const FlSpot(1, 1.8),
            const FlSpot(2, 2.8),
            const FlSpot(3, 3),
            const FlSpot(4, 2.5),
            const FlSpot(5, 1.2),
            const FlSpot(6, 0.8),
          ], Cores.amarelo),
          _criarLinha([
            const FlSpot(0, 0.5),
            const FlSpot(1, 2.2),
            const FlSpot(2, 3.6),
            const FlSpot(3, 3.2),
            const FlSpot(4, 2.8),
            const FlSpot(5, 3.4),
            const FlSpot(6, 3.9),
          ], Cores.vermelho),
        ],
      ),
    );
  }

  LineChartBarData _criarLinha(List<FlSpot> pontos, Color cor) {
    return LineChartBarData(
      spots: pontos,
      isCurved: true,
      color: cor,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
    );
  }
}
