import 'package:flutter/material.dart';
import 'custom_card.dart';
import 'custom_textos.dart';
import 'custom_botao.dart';
import '../utils/cores.dart';

class CustomDivider extends StatelessWidget {
  final double altura;
  final double espessura;
  final double recuoEsquerda;
  final double recuoDireita;
  final Color cor;

  const CustomDivider({
    super.key,
    this.altura = 1.0,
    this.espessura = 1.0,
    this.recuoEsquerda = 0.0,
    this.recuoDireita = 0.0,
    this.cor = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: recuoEsquerda, right: recuoDireita),
      child: Divider(
        height: altura,
        thickness: espessura,
        color: cor,
      ),
    );
  }
}

class ListaSemCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String textoBotao;
  final VoidCallback? onPressed;
  final Color corIndicador;
  final Color corBotao;

  const ListaSemCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.textoBotao,
    this.onPressed,
    this.corIndicador = Cores.azul,
    this.corBotao = Cores.azul,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: corIndicador,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      texto: titulo,
                      tamanho: 13,
                      peso: FontWeight.bold,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      texto: subtitulo,
                      tamanho: 11,
                      cor: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 30,
                child: Botao(
                  texto: textoBotao,
                  fontSize: 11,
                  backgroundColor: corBotao,
                  largura: 95,
                  onPressed: onPressed ?? () {},
                ),
              ),
            ],
          ),
        ),
        const CustomDivider(altura: 1),
      ],
    );
  }
}

class ListaComCard extends StatelessWidget {
  final String tituloCard;
  final List<Widget> itens;

  const ListaComCard({
    super.key,
    required this.tituloCard,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    return CardPadrao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitulo(
            titulo: tituloCard,
          ),
          ...itens,
        ],
      ),
    );
  }
}
