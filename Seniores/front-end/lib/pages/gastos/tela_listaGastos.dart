import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../models/gasto.dart';
import '../../services/api_service.dart';
import 'tela_novoGasto.dart';

class ListaGastos extends StatefulWidget {
  const ListaGastos({super.key});

  @override
  State<ListaGastos> createState() => _ListaGastosScreenState();
}

class _ListaGastosScreenState extends State<ListaGastos> {
  final ApiService _apiService = ApiService();
  List<Gasto> _gastos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final dados = await _apiService.listarRegistros('gastos');
      if (mounted) {
        setState(() {
          _gastos = dados.map((e) => Gasto.fromMap(e)).toList();
        });
      }
    } catch (_) {}
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 24, color: Cores.preto),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const AppText(
                        texto: 'Lista de gastos', 
                        estilo: AppText.titulo, 
                        tamanho: 24, 
                        peso: FontWeight.bold,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Cores.azul),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _gastos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80.0),
                      child: Center(
                        child: Text(
                          "Ainda não foi criada nenhuma categoria.",
                          style: TextStyle(
                            color: Cores.cinza,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gastos.length,
                      itemBuilder: (context, index) {
                        final gasto = _gastos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CardPadrao(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gasto.categoria,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Cores.azul,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        gasto.tipo,
                                        style: const TextStyle(
                                          color: Cores.cinza,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "R\$ ${gasto.valor.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 2,
                                          ),
                                          minimumSize: const Size(60, 30),
                                          side: const BorderSide(color: Cores.azul),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: const Text(
                                          "Editar",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Cores.azul,
                                          ),
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
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovoGasto()),
          );
          _carregar();
        },
        backgroundColor: Cores.azul,
        child: const Icon(Icons.add, color: Cores.branco),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}