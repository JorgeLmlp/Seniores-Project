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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            size: 24,
                            color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                          child: AppText(
                        texto: 'Lista de gastos',
                        estilo: AppText.titulo,
                        tamanho: 24,
                        peso: FontWeight.bold,
                      )),
                    ],
                  )),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Cores.azul),
                    onPressed: _carregar,
                  ),
                ],
              ),
              SizedBox(height: 20),
              _gastos.isEmpty
                  ? Padding(
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
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _gastos.length,
                      itemBuilder: (context, index) {
                        final gasto = _gastos[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: CardPadrao(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gasto.categoria,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Cores.azul,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        gasto.tipo,
                                        style: TextStyle(
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 2,
                                          ),
                                          minimumSize: Size(60, 30),
                                          side: BorderSide(color: Cores.azul),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      NovoGasto(gasto: gasto)));
                                          if (mounted) await _carregar();
                                        },
                                        child: Text(
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
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NovoGasto()),
          );
          _carregar();
        },
        backgroundColor: Cores.azul,
        child: Icon(Icons.add, color: Cores.branco),
      ),
      bottomNavigationBar: Menu(paginaAtual: 0),
    );
  }
}
