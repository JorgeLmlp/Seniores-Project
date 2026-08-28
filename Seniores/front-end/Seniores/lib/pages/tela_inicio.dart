import 'package:flutter/material.dart';
import 'package:widgets/widgets/custom_menuSanduiche.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_bolinhas.dart';
import '../models/registroDiario.dart';
import '../utils/cores.dart';
import '../pages/registro diario/tela_registroDiario.dart';
import '../services/api_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Registro? registroAtual;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _carregarUltimoRegistro();
  }

  Future<void> _carregarUltimoRegistro() async {
    try {
      final registros = await _apiService.listarDiarios();
      if (mounted && registros.isNotEmpty) {
        setState(() => registroAtual = Registro.fromApiJson(registros.first));
      }
    } on ApiException {
      // As telas de cadastro exibem erros; a home continua utilizável sem diário.
    }
  }

  Future<void> _abrirRegistroDiario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroDiario()),
    );

    if (resultado != null && resultado is Registro) {
      setState(() {
        registroAtual = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      endDrawer: const MenuSanduiche(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        texto: "Olá, {user}!",
                        tamanho: 28,
                        peso: FontWeight.bold,
                        cor: Cores.preto,
                        estilo: AppText.titulo,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        texto: "Como você está se sentindo hoje?",
                        tamanho: 14,
                        cor: Cores.cinza,
                        estilo: AppText.corpo,
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon:
                          const Icon(Icons.menu, size: 28, color: Cores.preto),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CardPadrao(
                      altura: 95,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: const [
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CardPadrao(
                      altura: 95,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: const [
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardPadrao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardTitulo(
                      titulo: "Diário de saúde",
                      data: registroAtual?.dataFormatada ?? "Hoje",
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: registroAtual == null
                          ? Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Cores.cinza, size: 18),
                                    SizedBox(width: 5),
                                    Text(
                                      "0 incidentes registrados hoje",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Registre humor, dor e eventos\npara acompanhar a evolução",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Cores.cinza),
                                ),
                                const SizedBox(height: 16),
                                Botao(
                                  texto: 'Registrar dia de hoje',
                                  icone: Icons.edit_square,
                                  largura: 240,
                                  altura: 45,
                                  fontSize: 14,
                                  backgroundColor: Cores.azul,
                                  textColor: Cores.branco,
                                  onPressed: _abrirRegistroDiario,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      const VerticalDivider(
                                          thickness: 2, color: Cores.cinza),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          IndicadorPontos(
                                            label: "Humor",
                                            valor:
                                                registroAtual!.humor.toDouble(),
                                          ),
                                          IndicadorPontos(
                                            label: "Dor",
                                            valor:
                                                registroAtual!.dor.toDouble(),
                                            inverso: true,
                                          ),
                                          IndicadorPontos(
                                            label: "Apetite",
                                            valor: registroAtual!.apetite
                                                .toDouble(),
                                          ),
                                          IndicadorPontos(
                                            label: "Mobilidade",
                                            valor: registroAtual!.mobilidade
                                                .toDouble(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Cores.amarelo, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${registroAtual!.totalIncidentes} incidente(s) registrado(s) hoje",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text("Tendência: ",
                                        style: TextStyle(
                                            color: Cores.cinza, fontSize: 13)),
                                    Text(
                                      registroAtual!.tendencia ?? 'Estável',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.trending_down,
                                        size: 18, color: Cores.vermelho),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CardPadrao(
                child: const Column(
                  children: [
                    CardTitulo(titulo: "Próximos medicamentos"),
                    ListTile(
                      title: Text(""),
                      subtitle: Text(""),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}
