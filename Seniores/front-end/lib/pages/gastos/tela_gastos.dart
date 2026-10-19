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

  void _mostrarPopupNovoGasto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 300,
          child: PopupNovoGastoContent(
            listaGastosAtuais: _listaGastos,
            onSalvo: () {
              Navigator.pop(context);
              _carregarGastos();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 24, color: Cores.preto),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const AppText(
                          texto: 'Gastos',
                          estilo: AppText.titulo,
                          tamanho: 24,
                          peso: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_listaGastos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            children: const [
                              Icon(Icons.account_balance_wallet_outlined, size: 64, color: Cores.cinza),
                              SizedBox(height: 16),
                              Text(
                                "Ainda não há nenhum registro.",
                                style: TextStyle(color: Cores.cinza, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      CardPadrao(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Gráfico de gastos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Cores.azul)),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 160,
                                child: Center(
                                  child: Icon(Icons.pie_chart, size: 130, color: Cores.azul.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CardPadrao(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Resumo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Cores.azul)),
                              const SizedBox(height: 16),
                              ..._listaGastos.map((gasto) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(gasto.categoria, style: const TextStyle(color: Cores.cinza, fontWeight: FontWeight.w500)),
                                        Text("R\$ ${gasto.valor.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Cores.preto)),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ],

                    const SizedBox(height: 20),

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
                            MaterialPageRoute(builder: (_) => const ListaGastos()),
                          );
                          _carregarGastos();
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarPopupNovoGasto,
        backgroundColor: Cores.azul,
        child: const Icon(Icons.add, color: Cores.branco),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}

class PopupNovoGastoContent extends StatefulWidget {
  final List<Gasto> listaGastosAtuais;
  final VoidCallback onSalvo;

  const PopupNovoGastoContent({
    super.key,
    required this.listaGastosAtuais,
    required this.onSalvo,
  });

  @override
  State<PopupNovoGastoContent> createState() => _PopupNovoGastoContentState();
}

class _PopupNovoGastoContentState extends State<PopupNovoGastoContent> {
  String? categoriaSelecionada;
  final TextEditingController _valorController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final categoriasUnicas = widget.listaGastosAtuais.map((e) => e.categoria).toSet().toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Novo gasto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.azul)),
        const SizedBox(height: 16),
        
        if (categoriasUnicas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              "Nenhuma categoria foi criada ainda",
              style: TextStyle(color: Cores.vermelho, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          )
        else
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text("Selecione a categoria"),
            items: categoriasUnicas
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) => setState(() => categoriaSelecionada = val),
          ),
          
        const SizedBox(height: 16),
        TextField(
          controller: _valorController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "R\$ 0,00",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Botao(
            texto: 'Concluir',
            largura: 140,
            altura: 40,
            backgroundColor: Cores.azul,
            textColor: Cores.branco,
            onPressed: categoriasUnicas.isEmpty
                ? () {} 
                : () {
                  
                    Future.microtask(() async {
                      if (categoriaSelecionada != null && _valorController.text.isNotEmpty) {
                        try {
                          await _apiService.criarRegistro('gastos', {
                            'categoria': categoriaSelecionada,
                            'valor': double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0,
                            'tipo': 'Mensal',
                            'cor': 'azul',
                          });
                          widget.onSalvo();
                        } catch (_) {}
                      }
                    });
                  },
          ),
        ),
      ],
    );
  }
}