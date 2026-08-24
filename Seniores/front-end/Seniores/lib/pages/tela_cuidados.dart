import 'package:flutter/material.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_listas.dart'; 
import '../utils/cores.dart';

class Cuidados extends StatelessWidget {
  const Cuidados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.branco, // Ou const Color(0xFFF6F8FB)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal
              const Text(
                'Consultas e exames',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Cores.preto,
                ),
              ),
              const SizedBox(height: 20),

              ListaComCard(
                tituloCard: "Consultas",
                itens: [
                  //Estrutura da lista
                  ListaPadrao(
                    titulo: "Oftalmologista hoje",
                    subtitulo: "Com Dr. Roberto às 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.amarelo,
                    corBotao: Cores.amarelo,
                    onPressed: () {},
                  ),
                  ListaPadrao(
                    titulo: "Oftalmologista amanhã",
                    subtitulo: "Com Dr. Roberto às 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.azul,
                    corBotao: Cores.azul,
                    onPressed: () {},
                  ),
                 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Botao(
                            texto: 'Mais detalhes',
                            altura: 38,
                            fontSize: 12,
                            backgroundColor: Cores.branco,
                            textColor: Cores.azul,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Botao(
                            texto: 'Consulta Fácil',
                            altura: 38,
                            fontSize: 12,
                            backgroundColor: Cores.branco,
                            textColor: Cores.azul,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ListaComCard(
                tituloCard: "Exames",
                itens: [
                  //Estrutura da lista
                  ListaPadrao(
                    titulo: "Exame de sangue hoje",
                    subtitulo: "Laboratório fulano - 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.amarelo,
                    corBotao: Cores.amarelo,
                    onPressed: () {},
                  ),
                  ListaPadrao(
                    titulo: "Exame de sangue amanhã",
                    subtitulo: "Laboratório fulano - 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.azul,
                    corBotao: Cores.azul,
                    onPressed: () {},
                  ),
               
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Botao(
                        texto: 'Mais detalhes',
                        largura: 160,
                        altura: 38,
                        fontSize: 12,
                        backgroundColor: Cores.branco,
                        textColor: Cores.azul,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}