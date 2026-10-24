import 'package:flutter/material.dart';
import '../../widgets/custom_graficos.dart';

class RelatorioGrafico extends StatelessWidget {
  const RelatorioGrafico({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Evolução do diário')),
      body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Evolução dos registros',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
                'Valores registrados no diário, na escala de 0 a 10. Toque nos pontos para consultar a data.'),
            SizedBox(height: 24),
            SizedBox(height: 320, child: GraficoEstatisticas()),
          ])));
}
