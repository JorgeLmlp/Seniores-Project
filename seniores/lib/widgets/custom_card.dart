import 'package:flutter/material.dart';

class CardPadrao extends StatelessWidget {
  final Widget child;
  final double? largura;
  final double? altura;
  final EdgeInsetsGeometry? padding;

  const CardPadrao({
    super.key,
    required this.child,
    this.largura,
    this.altura,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CardTitulo extends StatelessWidget {
  final String titulo;
  final String? data;
  final Color corFundo;
  final Color corTexto;
  final double tamanhoTitulo;
  final double tamanhoData;
  final double raio;

  const CardTitulo({
    super.key,
    required this.titulo,
    this.data,
    this.corFundo = const Color(0xFF275DAD),
    this.corTexto = Colors.white,
    this.tamanhoTitulo = 20,
    this.tamanhoData = 20,
    this.raio = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(raio),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: corTexto,
                fontSize: tamanhoTitulo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (data != null)
            Text(
              data!,
              style: TextStyle(
                color: corTexto,
                fontSize: tamanhoData,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}