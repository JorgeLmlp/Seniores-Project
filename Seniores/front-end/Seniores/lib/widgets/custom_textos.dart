import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String texto;
  final TextStyle? estilo;
  final double? tamanho;
  final FontWeight? peso;
  final Color? cor;

  const AppText({
    super.key,
    required this.texto,
    this.estilo,
    this.tamanho,
    this.peso,
    this.cor,
  });

  static const TextStyle titulo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitulo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle corpo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    final TextStyle estiloBase = estilo ?? corpo;

    return Text(
      texto,
      style: estiloBase.copyWith(
        fontSize: tamanho ?? estiloBase.fontSize,
        fontWeight: peso ?? estiloBase.fontWeight,
        color: cor ?? estiloBase.color ?? Colors.black,
        fontFamily: 'Inter',
      ),
    );
  }
}