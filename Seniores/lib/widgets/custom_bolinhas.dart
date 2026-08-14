import 'package:flutter/material.dart';

class Bolinhas extends StatelessWidget {
  final int quantidade;
  final int preenchidas;
  final Color cor;

  const Bolinhas({
    super.key,
    required this.quantidade,
    required this.preenchidas,
    this.cor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        quantidade,
        (index) => Container(
          margin: const EdgeInsets.only(right: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: index < preenchidas ? cor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class IndicadorPontos extends StatelessWidget {
  final String label;
  final double valor;
  final bool inverso;

  const IndicadorPontos({
    super.key,
    required this.label,
    required this.valor,
    this.inverso = false,
  });

  Color _cor(int pontuacao) {
    if (inverso) {
      //Dor: 0-3 verde, 4-6 amarelo, 7-10 vermelho
      if (pontuacao <= 3) return Colors.green;
      if (pontuacao <= 6) return Colors.amber;

      return Colors.red;
    }

    //Humor, apetite e mobilidade: 0-3 vermelho, 4-6 amarelo, 7-10 verde
    if (pontuacao <= 3) return Color(0xFFEB5757); 
    if (pontuacao <= 6) return Color(0xFFF2C946); 
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final int quantidade = valor.round().clamp(0, 10);
    final cor = _cor(quantidade);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF636E72),
              ),
            ),
          ),
          Row(
            children: [
              for(int index = 0; index < 10; index++)
                Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (index < quantidade) ? cor : Color.fromARGB(255, 120, 133, 138), 
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
