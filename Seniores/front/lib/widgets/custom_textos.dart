import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String texto;
  final TextStyle? estilo;
  final double tamanho;
  final FontWeight peso;
  final Color cor;

  const AppText({
    super.key,
    this.estilo,
    required this.texto,
    this.tamanho = 16,
    this.peso = FontWeight.normal,
    this.cor = Colors.black,
  });

//titulo
static const TextStyle titulo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

//Subtitulo
  static const TextStyle subtitulo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

//Corpo de texto
  static const TextStyle corpo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
  );

 @override
Widget build(BuildContext context) {
  return Text(
    texto,
    style: (estilo ?? const TextStyle()).copyWith(
      fontSize: tamanho,
      fontWeight: peso,
      color: cor,
      fontFamily: 'Inter',
    ),
  );
}
}