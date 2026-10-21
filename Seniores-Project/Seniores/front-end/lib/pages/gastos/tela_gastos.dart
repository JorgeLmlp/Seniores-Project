import 'tela_novoGasto.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../models/gasto.dart';
import '../../services/api_service.dart';
import 'tela_listaGastos.dart';

class Gastos extends StatefulWidget {
  const Gastos({super.key});

  @override
  State<Gastos> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<Gastos> {
  final ApiService _apiService = ApiService();
  List<Gasto> _listaGastos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarGastos();
  }

  Future<void> _carregarGastos() async {
    try {
      final dados = await _apiService.listarRegistros('gastos');
      if (mounted) {
        setState(() {
          _listaGastos = dados.map((e) => Gasto.fromMap(e)).toList();
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _mostrarPopupNovoGasto() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NovoGasto()));
    if (mounted) await _carregarGastos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _carregando
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              size: 24,
                              color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                        AppText(
                          texto: 'Gastos',
                          estilo: AppText.titulo,
                          tamanho: 24,
                          peso: FontWeight.bold,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (_listaGastos.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 64, color: Cores.cinza),
                              SizedBox(height: 16),
                              Text(
                                "Ainda não há nenhum registro.",
                                style: TextStyle(
                                    color: Cores.cinza,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      CardPadrao(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Gráfico de gastos",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Cores.azul)),
                              SizedBox(height: 20),
                              SizedBox(
                                height: 160,
                                child: Center(
                                  child: Icon(Icons.pie_chart,
                                      size: 130,
                                      color: Cores.azul.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      CardPadrao(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Resumo",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Cores.azul)),
                              SizedBox(height: 16),
                              ..._listaGastos.map((gasto) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(gasto.categoria,
                                            style: TextStyle(
                                                color: Cores.cinza,
                                                fontWeight: FontWeight.w500)),
                                        Text(
                                            "R\$ ${gasto.valor.toStringAsFixed(2)}",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface)),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    Center(
                      child: Botao(
                        texto: 'Gerenciar',
                        icone: Icons.settings_outlined,
                        largura: 160,
                        altura: 45,
                        backgroundColor: Cores.azul,
                        textColor: Cores.branco,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ListaGastos()),
                          );
                          _carregarGastos();
                        },
                      ),
                    ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarPopupNovoGasto,
        backgroundColor: Cores.azul,
        child: Icon(Icons.add, color: Cores.branco),
      ),
      bottomNavigationBar: Menu(paginaAtual: 0),
    );
  }
}
