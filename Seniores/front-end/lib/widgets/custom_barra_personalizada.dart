import 'package:flutter/material.dart';
import '../utils/cores.dart';

class ItemNivelSaude extends StatelessWidget {
  final String titulo;
  final double valor;
  final ValueChanged<double> onChanged;
  final bool inverso; //quanto maior, pior

  const ItemNivelSaude({
    super.key,
    required this.titulo,
    required this.valor,
    required this.onChanged,
    this.inverso = false,
  });

  Color get corBarra {
    final nivel = (valor * 10).round();

    if (inverso) {
      //Dor
      if (nivel <= 3) {
        return Cores.verde;
      } else if (nivel <= 6) {
        return Cores.amarelo;
      } else {
        return Cores.vermelho;
      }
    } else {
      //Humor apetite e mobilidade
      if (nivel <= 3) {
        return Cores.vermelho;
      } else if (nivel <= 6) {
        return Cores.amarelo;
      } else {
        return Cores.verde;
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
