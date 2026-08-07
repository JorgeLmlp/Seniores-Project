import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_bolinhas.dart';
import 'tela_medicamentos.dart';
import 'tela_registroDiario.dart';
import '../models/registroDiario.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RegistroModel? registroAtual;

  Future<void> _abrirRegistroDiario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroDiario()),
    );

    if (resultado != null && resultado is RegistroModel) {
      setState(() {
        registroAtual = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "Cuidados",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.medication),
                title: const Text("Medicamentos"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Medicamentos(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text("Exames e consultas"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Diário de saúde"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Cuidadores"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Controle",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text("Comunicados"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text("Gastos"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text("Relatórios"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Apoio",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text("Dicionário"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Ajuda"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Configurações",
                  style: TextStyle(
                    color: Color(0xFF275DAD),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Configurações"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Minha conta"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        texto: "Olá, nome!",
                        tamanho: 28,
                        peso: FontWeight.bold,
                        cor: Colors.black,
                        estilo: AppText.titulo,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        texto: "Como você está se sentindo hoje?",
                        tamanho: 14,
                        cor: Color(0xFF636E72),
                        estilo: AppText.corpo,
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: CardPadrao(
                      altura: 95,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(width: 42, height: 42),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                SizedBox(height: 3),
                                Text("", style: TextStyle(fontSize: 10, color: Color(0xFF636E72))),
                              ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(width: 42, height: 42),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                SizedBox(height: 3),
                                Text("", style: TextStyle(fontSize: 10, color: Color(0xFF636E72))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Card diário de saúde
              CardPadrao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitulo(
                      titulo: "Diário de saúde",
                      data: "13/04",
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: registroAtual == null
                          ? Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.grey, size: 18),
                                    SizedBox(width: 5),
                                    Text("0 incidentes registrados hoje", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Text("Registre humor, dor e eventos\npara acompanhar a evolução", textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                Botao(
                                  texto: 'Registrar dia de hoje',
                                  icone: Icons.edit_square,
                                  largura: 250,
                                  altura: 45,
                                  fontSize: 15,
                                  backgroundColor: const Color(0xFF275DAD),
                                  textColor: Colors.white,
                                  onPressed: _abrirRegistroDiario,
                                ),
                              ],
                            ): Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      const VerticalDivider(thickness: 2, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          IndicadorPontos(label: "Humor", valor: registroAtual!.humor, corAtiva: Colors.amber),
                                          IndicadorPontos(label: "Dor", valor: registroAtual!.dor, corAtiva: Colors.green),
                                          IndicadorPontos(label: "Apetite", valor: registroAtual!.apetite, corAtiva: Colors.redAccent),
                                          IndicadorPontos(label: "Mobilidade", valor: registroAtual!.mobilidade, corAtiva: Colors.green),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${registroAtual!.totalIncidentes} incidente registrado hoje",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text("Tendência: ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    Text(
                                      registroAtual!.tendencia,
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.trending_down, size: 18),
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
                    CardTitulo(
                      titulo: "Próximos medicamentos",
                    ),
                    ListTile(
                      title: Text(""),
                      subtitle: Text(""),
                    ),
                    Divider(),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const Menu(
        paginaAtual: 0,
      ),
    );
  }
}