import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../utils/cores.dart';
import '../../models/cuidador.dart';

class DetalheCuidador extends StatelessWidget {
  final Cuidador cuidador;

  const DetalheCuidador({super.key, required this.cuidador});

  @override
  Widget build(BuildContext context) {
    final diasFrequencia = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Cores.preto, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const AppText(
                      texto: 'Cuidador', estilo: AppText.titulo, tamanho: 24),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  CardPadrao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Cores.cinza.withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Cores.cinza, size: 34),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                      texto: cuidador.nome,
                                      estilo: AppText.titulo,
                                      tamanho: 18),
                                  AppText(
                                      texto: cuidador.funcao,
                                      estilo: AppText.corpo,
                                      tamanho: 12,
                                      cor: Cores.cinza),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Cores.azul),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppText(
                          texto:
                              '${cuidador.frequenciaResumida} - ${cuidador.horaInicio} ás ${cuidador.horaFim}',
                          estilo: AppText.corpo,
                          tamanho: 13,
                          peso: FontWeight.w600,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          texto: cuidador.observacoes.isEmpty
                              ? 'Nenhuma observação informada'
                              : cuidador.observacoes,
                          estilo: AppText.corpo,
                          tamanho: 12,
                          cor: Cores.cinza,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                color: Cores.azul, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              cuidador.telefone1.isEmpty
                                  ? 'Não informado'
                                  : cuidador.telefone1,
                              style: const TextStyle(
                                  color: Cores.azul,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (cuidador.telefone2.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  color: Cores.azul, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                cuidador.telefone2,
                                style: const TextStyle(
                                    color: Cores.azul,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AppText(
                      texto: 'Frequência',
                      estilo: AppText.subtitulo,
                      tamanho: 16,
                      cor: Cores.azul),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(diasFrequencia.length, (index) {
                      final ativo = cuidador.frequencia[index];
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ativo ? Cores.azul : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: ativo
                                  ? Cores.azul
                                  : Cores.cinza.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text(
                            diasFrequencia[index],
                            style: TextStyle(
                              color: ativo ? Colors.white : Cores.azul,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}
