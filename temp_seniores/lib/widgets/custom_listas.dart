import 'package:flutter/material.dart';
import 'custom_card.dart';
import 'custom_textos.dart';
import 'custom_botao.dart';

//Lista sem Card
class ListaPadrao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String textoBotao;
  final VoidCallback? onPressed;
  final Color corIndicador;
  final Color corBotao;

  const ListaPadrao({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.textoBotao,
    this.onPressed,
    this.corIndicador = const Color(0xFF275DAD),
    this.corBotao = const Color(0xFF275DAD),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
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

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      texto: titulo,
                      tamanho: 15,
                      peso: FontWeight.w600,
                    ),
                    AppText(
                      texto: subtitulo,
                      tamanho: 12,
                      cor: Colors.grey,
                    ),
                  ],
                ),
              ),

              Botao(
                texto: textoBotao,
                largura: 100,
                altura: 32,
                fontSize: 12,
                backgroundColor: corBotao,
                onPressed: onPressed ?? () {},
              ),
            ],
          ),
        ),

        const Divider(height: 1),
      ],
    );
  }
}

//Lista com Card
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