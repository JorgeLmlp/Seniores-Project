import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../utils/cores.dart';

class RelatorioGrafico extends StatelessWidget {
  const RelatorioGrafico({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Cores.preto, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Relatório',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Cores.preto),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  // Card do Gráfico
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estatisticas',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Cores.azul),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(
                          height: 160,
                          child: GraficoEstatisticas(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _LegendaItem(cor: Cores.azul, texto: 'Humor'),
                            _LegendaItem(cor: Cores.verde, texto: 'Sono'),
                            _LegendaItem(cor: Cores.amarelo, texto: 'Dor'),
                            _LegendaItem(cor: Cores.vermelho, texto: 'Pressão'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                          child: _buildCardStatus('Humor', 'Feliz', 'Normal',
                              Icons.sentiment_satisfied, Cores.azul)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildCardStatus('Sono', '7h40', 'Bom',
                              Icons.nightlight_round, Cores.verde)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildCardStatus('Dor', '12%', 'Parcial',
                              Icons.heart_broken, Cores.amarelo)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildCardStatus('Pressão', '62bpm', 'Normal',
                              Icons.favorite, Cores.vermelho)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Resumo',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Cores.azul),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'texto descritivo do resumo diário ou geral gerado pelo sistema...',
                          style: TextStyle(fontSize: 13, color: Cores.cinza),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 3),
    );
  }

  Widget _buildCardStatus(
      String titulo, valor, String status, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(height: 4),
          Text(titulo,
              style: TextStyle(
                  fontSize: 11, color: cor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Cores.preto)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 9, color: cor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

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
            const FlSpot(6, 2.5)
          ], Cores.azul),
          _criarLinha([
            const FlSpot(0, 2.5),
            const FlSpot(1, 3),
            const FlSpot(2, 2),
            const FlSpot(3, 1),
            const FlSpot(4, 0.5),
            const FlSpot(5, 2.5),
            const FlSpot(6, 3.8)
          ], Cores.verde),
          _criarLinha([
            const FlSpot(0, 1.5),
            const FlSpot(1, 1.8),
            const FlSpot(2, 2.8),
            const FlSpot(3, 3),
            const FlSpot(4, 2.5),
            const FlSpot(5, 1.2),
            const FlSpot(6, 0.8)
          ], Cores.amarelo),
          _criarLinha([
            const FlSpot(0, 0.5),
            const FlSpot(1, 2.2),
            const FlSpot(2, 3.6),
            const FlSpot(3, 3.2),
            const FlSpot(4, 2.8),
            const FlSpot(5, 3.4),
            const FlSpot(6, 3.9)
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

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String texto;
  const _LegendaItem({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

//OBS : O GRAFICO E ESTATICO
