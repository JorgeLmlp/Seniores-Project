import 'package:flutter/material.dart';

class Botao extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  final double largura;
  final double altura;
  final double fontSize;
  final double borderRadius;
  final double borderWidth;

  final IconData? icone;

  const Botao({
    super.key,
    required this.texto,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF275DAD),
    this.textColor = Colors.white,
    this.borderColor = Colors.transparent,
    this.largura = double.infinity,
    this.altura = 55,
    this.fontSize = 16,
    this.borderRadius = 12,
    this.borderWidth = 0,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      height: altura,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: borderColor,
              width: borderWidth,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icone != null) ...[
              Icon(
                icone,
                size: 20,
                color: textColor,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              texto,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grupo de botões
class GrupoBotoes extends StatelessWidget {
  final List<String> itens;
  final int selecionado;
  final Function(int) onSelecionado;

  const GrupoBotoes({
    super.key,
    required this.itens,
    required this.selecionado,
    required this.onSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF275DAD),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: List.generate(itens.length, (index) {
            final ativo = index == selecionado;

            return Expanded(
              child: InkWell(
                onTap: () => onSelecionado(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: ativo
                        ? const Color(0xFF275DAD)
                        : Colors.white,
                    borderRadius: BorderRadius.horizontal(
                      left: index == 0
                          ? const Radius.circular(25)
                          : Radius.zero,
                      right: index == itens.length - 1
                          ? const Radius.circular(25)
                          : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        itens[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ativo
                              ? Colors.white
                              : const Color(0xFF275DAD),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}