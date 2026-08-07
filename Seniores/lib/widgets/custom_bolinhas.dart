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
            color: index < preenchidas
                ? cor
                : Colors.grey.shade300,
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
  final Color corAtiva;

  const IndicadorPontos({
    super.key,
    required this.label,
    required this.valor,
    required this.corAtiva,
  });

  @override
  Widget build(BuildContext context) {
    int totalPreenchidos = valor.toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final bool isActive = index < totalPreenchidos;
              return Container(
                margin: const EdgeInsets.only(right: 4.0),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? corAtiva : Colors.grey.shade400,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
