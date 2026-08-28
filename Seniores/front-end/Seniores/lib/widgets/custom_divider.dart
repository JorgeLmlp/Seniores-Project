import 'package:flutter/material.dart';

class CustomDivider extends StatelessWidget {
  final double altura;
  final Color cor;

  const CustomDivider({
    super.key,
    this.altura = 1.0,
    this.cor = const Color(0xFFEEEEEE),
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: altura,
      thickness: altura,
      color: cor,
    );
  }
}
