import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../models/cuidador.dart';
import 'tela_listaCuidadores.dart';
import '../cuidadores/tela_detalhesCuidador.dart';

class Cuidadores extends StatefulWidget {
  const Cuidadores({super.key});

  @override
  State<Cuidadores> createState() => _TelaCuidadosState();
}

class _TelaCuidadosState extends State<Cuidadores> {
  int diaSelecionado = 1;

  final List<Map<String, String>> dias = [
    {'dia': '12', 'mes': 'Abril'},
    {'dia': '13', 'mes': 'Abril'},
    {'dia': '14', 'mes': 'Abril'},
    {'dia': '15', 'mes': 'Abril'},
    {'dia': '16', 'mes': 'Abril'},
  ];

  final Cuidador cuidadorAgora = Cuidador(
    nome: 'Mônica',
    funcao: 'Medicação e alimentação',
    horaInicio: '10:00',
    horaFim: '14:00',
    frequencia: [false, true, true, true, true, true, false],
    observacoes: 'Levar para caminhar às 11h e dar o remédio com água.',
    ativoAgora: true,
  );

  final List<Cuidador> proximosCuidadores = [
    Cuidador(
      nome: 'José',
      funcao: 'Exercícios',
      horaInicio: '18:00',
      horaFim: '20:00',
      frequencia: [true, true, true, true, true, true, true],
      observacoes: 'Fazer apenas alongamentos leves solicitados pelo médico.',
    ),
    Cuidador(
      nome: 'José',
      funcao: 'Exercícios',
      horaInicio: '18:00',
      horaFim: '20:00',
      frequencia: [true, true, true, true, true, true, true],
      observacoes: 'Verificar pressão arterial antes de iniciar.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.canPop(context)
                        ? Navigator.pop(context)
                        : null,
                  ),
                  const AppText(
                      texto: 'Cuidadores', estilo: AppText.titulo, tamanho: 24),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(dias.length, (index) {
                    final selecionado = index == diaSelecionado;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () => setState(() => diaSelecionado = index),
                        child: Container(
                          width: 55,
                          height: 75,
                          decoration: BoxDecoration(
                            color: selecionado ? Cores.azul : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: selecionado
                                    ? Cores.azul
                                    : Cores.cinza.withOpacity(0.3)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dias[index]['dia']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      selecionado ? Colors.white : Cores.preto,
                                ),
                              ),
                              Text(
                                dias[index]['mes']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      selecionado ? Colors.white : Cores.cinza,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                DetalheCuidador(cuidador: cuidadorAgora))),
                    child: CardPadrao(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Cores.cinza.withOpacity(0.2),
                                child: const Icon(Icons.person,
                                    color: Cores.cinza, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                        texto: cuidadorAgora.nome,
                                        estilo: AppText.corpo,
                                        peso: FontWeight.bold,
                                        tamanho: 16),
                                    AppText(
                                        texto: cuidadorAgora.funcao,
                                        estilo: AppText.corpo,
                                        tamanho: 12,
                                        cor: Cores.cinza),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Cores.azul,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Agora',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1),
                          ),
                          AppText(
                            texto: cuidadorAgora.observacoes.isNotEmpty
                                ? cuidadorAgora.observacoes
                                : 'Sem observações',
                            estilo: AppText.corpo,
                            tamanho: 11,
                            cor: Cores.cinza,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                  texto:
                                      '${cuidadorAgora.horaInicio} ás ${cuidadorAgora.horaFim}',
                                  estilo: AppText.corpo,
                                  tamanho: 13,
                                  peso: FontWeight.w600),
                              SizedBox(
                                height: 32,
                                width: 100,
                                child: Botao(
                                  texto: 'Informações',
                                  fontSize: 11,
                                  borderRadius: 16,
                                  backgroundColor: Colors.white,
                                  textColor: Cores.azul,
                                  borderColor: Cores.azul,
                                  borderWidth: 1,
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => DetalheCuidador(
                                              cuidador: cuidadorAgora))),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AppText(
                      texto: 'Próximos cuidadores',
                      estilo: AppText.subtitulo,
                      tamanho: 16,
                      cor: Cores.azul),
                  const SizedBox(height: 8),
                  ...proximosCuidadores.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DetalheCuidador(cuidador: c))),
                          child: CardPadrao(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Cores.cinza.withOpacity(0.2),
                                  child: const Icon(Icons.person,
                                      color: Cores.cinza, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                          texto: c.nome,
                                          estilo: AppText.corpo,
                                          peso: FontWeight.bold,
                                          tamanho: 15),
                                      AppText(
                                          texto: c.funcao,
                                          estilo: AppText.corpo,
                                          tamanho: 12,
                                          cor: Cores.cinza),
                                      const SizedBox(height: 4),
                                      AppText(
                                        texto: c.observacoes.isNotEmpty
                                            ? c.observacoes
                                            : 'Sem observações',
                                        estilo: AppText.corpo,
                                        tamanho: 11,
                                        cor: Cores.cinza,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppText(
                                        texto:
                                            '${c.horaInicio} ás ${c.horaFim}',
                                        estilo: AppText.corpo,
                                        tamanho: 12,
                                        peso: FontWeight.bold),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 28,
                                      width: 90,
                                      child: Botao(
                                        texto: 'Informações',
                                        fontSize: 10,
                                        borderRadius: 14,
                                        backgroundColor: Colors.white,
                                        textColor: Cores.azul,
                                        borderColor: Cores.azul,
                                        borderWidth: 1,
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => DetalheCuidador(
                                                    cuidador: c))),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Cores.amarelo, size: 16),
                      SizedBox(width: 6),
                      Text('Sem cuidador das 14:00 ás 18:00',
                          style: TextStyle(
                              color: Cores.amarelo,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Botao(
                    texto: 'Ver todos cuidadores',
                    fontSize: 14,
                    borderRadius: 10,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ListaCuidadores())),
                  ),
                  const SizedBox(height: 20),
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
