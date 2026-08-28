import 'package:flutter/material.dart';
import '../utils/cores.dart';

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
      if (pontuacao <= 3) return Cores.verde;
      if (pontuacao <= 6) return Cores.amarelo;

      return Cores.vermelho;
    }

    if (pontuacao <= 3) return Cores.vermelho;
    if (pontuacao <= 6) return Cores.amarelo;

    return Cores.verde;
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
                color: Cores.cinza,
              ),
            ),
          ),
          Row(
            children: [
              for (int index = 0; index < 10; index++)
                Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (index < quantidade) ? cor : Cores.cinza,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class BarraIndicador extends StatelessWidget {
  final String label;
  final double valor;
  final bool inverso;

  const BarraIndicador({
    super.key,
    required this.label,
    required this.valor,
    this.inverso = false,
  });

  Color _obterCor(int blocosPreenchidos) {
    if (inverso) {
      if (blocosPreenchidos <= 1) return Cores.verde;
      if (blocosPreenchidos <= 3) return Cores.vermelho;

      return Cores.vermelho;
    }

    if (blocosPreenchidos <= 1) return Cores.vermelho;
    if (blocosPreenchidos <= 3) return Cores.amarelo;

    return Cores.verde;
  }

  @override
  Widget build(BuildContext context) {
    final int blocos = (valor / 2).round().clamp(0, 5);
    final Color cor = _obterCor(blocos);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Cores.azul,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < 5; i++) ...[
                Expanded(
                  child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: i < blocos ? cor : const Color(0xFFBDC8D6),
                        borderRadius: BorderRadius.circular(4),
                      )),
                ),
                if (i < 4)
                  const SizedBox(width: 4), // Espaçamento entre os blocos
              ],
            ],
          ),
        ],
      ),
    );
  }
}
