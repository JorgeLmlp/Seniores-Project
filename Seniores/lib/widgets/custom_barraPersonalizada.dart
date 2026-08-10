import 'package:flutter/material.dart';

class ItemNivelSaude extends StatelessWidget {
  final String titulo;
  final double valor;
  final ValueChanged<double> onChanged;

  // true = quanto maior, pior
  final bool inverso;

  const ItemNivelSaude({
    super.key,
    required this.titulo,
    required this.valor,
    required this.onChanged,
    this.inverso = false,
  });

  Color get corBarra {
    // Converte 0.0 - 1.0 para 0 - 10
    final nivel = (valor * 10).round();

    if (inverso) {
      // Dor
      if (nivel <= 3) {
        return Colors.green;
      } else if (nivel <= 6) {
        return Colors.amber;
      } else {
        return Colors.red;
      }
    } else {
      // Humor, apetite e mobilidade
      if (nivel <= 3) {
        return Colors.red;
      } else if (nivel <= 6) {
        return Colors.amber;
      } else {
        return Colors.green;
      }
    }
  }

  String get descricao {
    final nivel = (valor * 10).round();

    if (inverso) {
      if (nivel <= 3) {
        return 'Baixa';
      } else if (nivel <= 6) {
        return 'Moderada';
      } else {
        return 'Alta';
      }
    } else {
      if (nivel <= 3) {
        return 'Baixo';
      } else if (nivel <= 6) {
        return 'Neutro';
      } else {
        return 'Ótimo';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                '$descricao • ${(valor * 10).round()}/10',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: corBarra,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: corBarra,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: corBarra,
              trackHeight: 6,

              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
              ),

              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 18,
              ),
            ),

            child: Slider(
              value: valor,
              min: 0,
              max: 1,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}