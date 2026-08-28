import 'package:flutter/material.dart';
import 'package:widgets/pages/cuidados/tela_detalhesConsulta.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_listas.dart';
import '../../utils/cores.dart';
import 'tela_consultas.dart';
import 'tela_exames.dart';

class Cuidados extends StatelessWidget {
  const Cuidados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  //estrutura da lista
                  ListaSemCard(
                    titulo: "Oftalmologista hoje",
                    subtitulo: "Com Dr. Roberto às 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.amarelo,
                    corBotao: Cores.amarelo,
                    onPressed: () {},
                  ),
                  ListaSemCard(
                    titulo: "Oftalmologista amanhã",
                    subtitulo: "Com Dr. Roberto às 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.azul,
                    corBotao: Cores.azul,
                    onPressed: () {},
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Botao(
                            texto: 'Mais detalhes',
                            altura: 38,
                            fontSize: 12,
                            backgroundColor: Cores.branco,
                            textColor: Cores.azul,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Consultas(),
                                ),
                              );
                            },
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
                  //estrutura da lista
                  ListaSemCard(
                    titulo: "Exame de sangue hoje",
                    subtitulo: "Laboratório fulano - 16:00",
                    textoBotao: "Informações",
                    corIndicador: Cores.amarelo,
                    corBotao: Cores.amarelo,
                    onPressed: () {},
                  ),
                  ListaSemCard(
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Exames(),
                            ),
                          );
                        },
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
