import 'package:flutter/material.dart';
import '../utils/cores.dart';

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
    this.corFundo = Cores.azul,
    this.corTexto = Colors.white,
    this.tamanhoTitulo = 18,
    this.tamanhoData = 16,
    this.raio = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(raio),
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
          if (data != null) ...[
            const SizedBox(width: 8),
            Text(
              data!,
              style: TextStyle(
                color: corTexto,
                fontSize: tamanhoData,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
