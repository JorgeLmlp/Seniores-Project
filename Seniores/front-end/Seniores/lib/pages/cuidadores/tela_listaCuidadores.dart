import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../models/cuidador.dart';
import '../cuidadores/tela_cadastroCuidador.dart';
import '../cuidadores/tela_detalhesCuidador.dart';
import '../../services/api_service.dart';

class ListaCuidadores extends StatefulWidget {
  const ListaCuidadores({super.key});

  @override
  State<ListaCuidadores> createState() => _ListaCuidadoresState();
}

class _ListaCuidadoresState extends State<ListaCuidadores> {
  final List<Cuidador> lista = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final registros = await _apiService.listarRegistros('cuidadores');
      if (!mounted) return;
      setState(() => lista.addAll(registros.map((registro) =>
          Cuidador.fromJson(registro['dados'] as Map<String, dynamic>))));
    } on ApiException catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Cores.preto, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const AppText(
                          texto: 'Cuidadores',
                          estilo: AppText.titulo,
                          tamanho: 24),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final c = lista[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetalheCuidador(cuidador: c))),
                      child: CardPadrao(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                          tamanho: 16),
                                      AppText(
                                          texto: c.funcao,
                                          estilo: AppText.corpo,
                                          tamanho: 12,
                                          cor: Cores.cinza),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Cores.azul,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(c.frequenciaResumida,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                    texto: '${c.horaInicio} ás ${c.horaFim}',
                                    estilo: AppText.corpo,
                                    tamanho: 12,
                                    peso: FontWeight.w600),
                                SizedBox(
                                  height: 30,
                                  width: 95,
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
                                            builder: (_) =>
                                                DetalheCuidador(cuidador: c))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Cores.azul,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final novoCuidador = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroCuidador()),
          );

          if (novoCuidador != null && novoCuidador is Cuidador) {
            setState(() {
              lista.add(novoCuidador);
            });
          }
        },
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}
