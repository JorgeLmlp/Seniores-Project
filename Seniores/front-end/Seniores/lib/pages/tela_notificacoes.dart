import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../utils/cores.dart';
import '../../models/notificacao.dart';
import 'tela_inicio.dart';

class Notificacoes extends StatefulWidget {
  const Notificacoes({super.key});

  @override
  State<Notificacoes> createState() => _NotificacoesState();
}

class _NotificacoesState extends State<Notificacoes> {
  int indiceSelecionado = 0;
  final List<String> categoriasFiltro = [
    'Todas',
    'Alertas',
    'Agendamentos',
    'Medicamentos'
  ];
  final List<IconData> iconesFiltro = [
    Icons.notifications,
    Icons.warning_amber_rounded,
    Icons.calendar_today,
    Icons.medication,
  ];

  //Estruturas da lista
  final List<Notificacao> todasNotificacoes = [
    Notificacao(
      titulo: 'Horário do medicamento',
      subtitulo: 'Dipirona 500mg\nÉ hora de tomar seu medicamento das 12:00.',
      horario: '12:00',
      icone: Icons.medication,
      corIcone: Cores.verde,
      categoria: 'Medicamentos',
      secao: 'Hoje',
    ),
    Notificacao(
      titulo: 'Consulta confirmada',
      subtitulo: 'Consulta com Dr. João Silva\nAmanhã, 22/04 às 14:00.',
      horario: '09:15',
      icone: Icons.calendar_today,
      corIcone: Cores.azul,
      categoria: 'Agendamentos',
      secao: 'Hoje',
    ),
    Notificacao(
      titulo: 'Lembrete de saúde',
      subtitulo: 'Não se esqueça de registrar seu diário de saúde hoje.',
      horario: '20:30',
      icone: Icons.warning_amber_rounded,
      corIcone: Cores.laranja,
      categoria: 'Alertas',
      secao: 'Ontem',
    ),
    Notificacao(
      titulo: 'Novo relatorio disponivel',
      subtitulo: 'Seu relatorio semanal ja esta disponivel para visualização.',
      horario: '18:45',
      icone: Icons.description_outlined,
      corIcone: Cores.roxo,
      categoria: 'Alertas',
      secao: 'Ontem',
    ),
    Notificacao(
      titulo: 'Meta semanal alcançada',
      subtitulo: 'Parabéns! Você alcançou sua meta de passos da semana.',
      horario: 'Terça-feira',
      icone: Icons.check_circle_outline,
      corIcone: Cores.verde,
      categoria: 'Alertas',
      secao: 'Esta semana',
    ),
    Notificacao(
      titulo: 'Hidratação',
      subtitulo: 'Você ainda não registrou sua ingestão de água hoje',
      horario: 'Segunda-feira',
      icone: Icons.water_drop_outlined,
      corIcone: Cores.azul,
      categoria: 'Alertas',
      secao: 'Esta semana',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categoriaAtual = categoriasFiltro[indiceSelecionado];
    final notificacoesFiltradas = categoriaAtual == 'Todas'
        ? todasNotificacoes
        : todasNotificacoes
            .where((n) => n.categoria == categoriaAtual)
            .toList();

    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Cores.preto),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Home()),
                                );
                              }
                            },
                          ),
                          const AppText(
                            texto: 'Notificações',
                            estilo: AppText.titulo,
                            tamanho: 24,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Cores.azul),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 4.0),
                    child: AppText(
                      texto:
                          'Fique por dentro do que é importante para a sua saúde.',
                      estilo: AppText.corpo,
                      tamanho: 13,
                      cor: Cores.cinza,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(categoriasFiltro.length, (index) {
                        final selecionado = indiceSelecionado == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildFiltroChip(
                            label: categoriasFiltro[index],
                            selecionado: selecionado,
                            icone: iconesFiltro[index],
                            onTap: () {
                              setState(() {
                                indiceSelecionado = index;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  if (notificacoesFiltradas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: AppText(
                          texto: 'Nenhuma notificação encontrada.',
                          estilo: AppText.corpo,
                          cor: Cores.cinza,
                        ),
                      ),
                    )
                  else ...[
                    if (_contemSecao(notificacoesFiltradas, 'Hoje')) ...[
                      const AppText(
                          texto: 'Hoje',
                          estilo: AppText.subtitulo,
                          tamanho: 16,
                          cor: Cores.azul),
                      const SizedBox(height: 8),
                      ..._gerarCardsPorSecao(notificacoesFiltradas, 'Hoje'),
                      const SizedBox(height: 16),
                    ],
                    if (_contemSecao(notificacoesFiltradas, 'Ontem')) ...[
                      const AppText(
                          texto: 'Ontem',
                          estilo: AppText.subtitulo,
                          tamanho: 16,
                          cor: Cores.azul),
                      const SizedBox(height: 8),
                      ..._gerarCardsPorSecao(notificacoesFiltradas, 'Ontem'),
                      const SizedBox(height: 16),
                    ],
                    if (_contemSecao(notificacoesFiltradas, 'Esta semana')) ...[
                      const AppText(
                          texto: 'Esta semana',
                          estilo: AppText.subtitulo,
                          tamanho: 16,
                          cor: Cores.azul),
                      const SizedBox(height: 8),
                      ..._gerarCardsPorSecao(
                          notificacoesFiltradas, 'Esta semana'),
                      const SizedBox(height: 16),
                    ],
                  ],
                  CardPadrao(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Cores.azul.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active,
                              color: Cores.azul),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                  texto: 'Ative as notificações',
                                  estilo: AppText.corpo,
                                  peso: FontWeight.bold),
                              AppText(
                                  texto:
                                      'Receba lembretes e alertas importantes.',
                                  estilo: AppText.corpo,
                                  tamanho: 12,
                                  cor: Cores.cinza),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Cores.azul,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {},
                          child: const Text('Ativar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 4),
    );
  }

  bool _contemSecao(List<Notificacao> lista, String secao) {
    return lista.any((n) => n.secao == secao);
  }

  List<Widget> _gerarCardsPorSecao(List<Notificacao> lista, String secao) {
    return lista
        .where((n) => n.secao == secao)
        .map((n) => _buildNotificacaoCard(
              icone: n.icone,
              corIcone: n.corIcone,
              titulo: n.titulo,
              subtitulo: n.subtitulo,
              horario: n.horario,
            ))
        .toList();
  }

  Widget _buildFiltroChip({
    required String label,
    required bool selecionado,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? Cores.azul : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selecionado ? Cores.azul : Cores.cinza.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icone,
                size: 16, color: selecionado ? Colors.white : Cores.azul),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selecionado ? Colors.white : Cores.preto,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacaoCard({
    required IconData icone,
    required Color corIcone,
    required String titulo,
    required String subtitulo,
    required String horario,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: CardPadrao(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: corIcone.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: corIcone, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                          texto: titulo,
                          estilo: AppText.corpo,
                          peso: FontWeight.bold,
                          tamanho: 14),
                      AppText(
                          texto: horario,
                          estilo: AppText.corpo,
                          tamanho: 11,
                          cor: Cores.cinza),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                      texto: subtitulo,
                      estilo: AppText.corpo,
                      tamanho: 12,
                      cor: Cores.cinza),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Cores.azul, size: 18),
          ],
        ),
      ),
    );
  }
}
