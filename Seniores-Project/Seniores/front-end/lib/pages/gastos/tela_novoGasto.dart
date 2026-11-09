import '../../models/gasto.dart';
import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import '../../utils/mascaras.dart';

class NovoGasto extends StatefulWidget {
  final Gasto? gasto;
  const NovoGasto({super.key, this.gasto});

  @override
  State<NovoGasto> createState() => _NovoGastoScreenState();
}

class _NovoGastoScreenState extends State<NovoGasto>
    with DraftState<NovoGasto> {
  @override
  Map<String, TextEditingController> get draftControllers => {
        '_nomeController': _nomeController,
        '_valorController': _valorController
      };

  @override
  Map<String, dynamic> get draftValues => {
        '_tipoSelecionado': _tipoSelecionado,
        '_corSelecionada': _corSelecionada
      };

  @override
  void restoreDraftValues(Map<String, dynamic> v) {
    if (v['_tipoSelecionado'] != null) {
      _tipoSelecionado = v['_tipoSelecionado'] as String;
    }
    if (v['_corSelecionada'] != null) {
      _corSelecionada = v['_corSelecionada'] as String;
    }
  }

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  String _tipoSelecionado = 'Mensal';
  String _corSelecionada = 'azul';
  bool _salvando = false;

  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _paletaCores = [
    {'nome': 'azul', 'cor': Cores.azul},
    {'nome': 'verde', 'cor': Cores.verde},
    {'nome': 'vermelho', 'cor': Cores.vermelho},
    {'nome': 'amarelo', 'cor': Cores.amarelo},
    {'nome': 'roxo', 'cor': Cores.roxo},
    {'nome': 'laranja', 'cor': Cores.laranja},
    {'nome': 'cinza', 'cor': Cores.cinza}
  ];

  @override
  String get draftName => 'gasto:${widget.gasto?.id ?? 'novo'}';
  @override
  void initState() {
    super.initState();
    final gasto = widget.gasto;
    if (gasto != null) {
      _nomeController.text = gasto.categoria;
      _valorController.text =
          gasto.valor.toStringAsFixed(2).replaceAll('.', ',');
      _tipoSelecionado = gasto.tipo;
      _corSelecionada = gasto.corHex;
    }
  }

  @override
  void dispose() {
    saveDraftBeforeDispose();
    _nomeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvarGasto() async {
    final nome = _nomeController.text.trim();
    final valorTexto = _valorController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, informe o nome da categoria.')),
      );
      return;
    }

    final digitsOnly = valorTexto.replaceAll(RegExp(r'\D'), '');
    final valor = digitsOnly.isEmpty ? 0.0 : double.parse(digitsOnly) / 100;

    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um valor maior que zero.')));
      return;
    }
    setState(() => _salvando = true);

    try {
      final dados = {
        'nome': nome,
        'categoria': nome,
        'valor': valor,
        'tipo': _tipoSelecionado,
        'cor': _corSelecionada,
      };
      if (widget.gasto == null) {
        await _apiService.criarRegistro('gastos', dados);
      } else {
        await _apiService.atualizarRegistro('gastos', widget.gasto!.id, dados);
      }

      await clearDraft();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar gasto: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
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
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  AppText(
                      texto: 'Novo gasto',
                      estilo: AppText.titulo,
                      tamanho: 24,
                      peso: FontWeight.bold),
                ],
              ),
              SizedBox(height: 24),
              Text("Nome da Categoria / Gasto",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 8),
              CampoTexto(
                hintText: "Ex: Farmácia, Consultas...",
                controller: _nomeController,
              ),
              SizedBox(height: 20),
              Text("Valor (R\$)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 8),
              CampoTexto(
                hintText: "0,00",
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [DinheiroInputFormatter()],
              ),
              SizedBox(height: 20),
              Text("Tipo",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 8),
              Row(
                children: ['Mensal', 'Anual'].map((tipo) {
                  bool selecionado = _tipoSelecionado == tipo;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              selecionado ? Cores.azul : Cores.branco,
                          side: BorderSide(color: Cores.azul),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () =>
                            setState(() => _tipoSelecionado = tipo),
                        child: Text(tipo,
                            style: TextStyle(
                                color: selecionado ? Cores.branco : Cores.azul,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text("Cor",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _paletaCores.map((item) {
                  bool selecionado = _corSelecionada == item['nome'];
                  return GestureDetector(
                    onTap: () => setState(() => _corSelecionada = item['nome']),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: item['cor'],
                        shape: BoxShape.circle,
                        border: selecionado
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3)
                            : null,
                      ),
                      child: selecionado
                          ? Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 40),
              Center(
                child: _salvando
                    ? CircularProgressIndicator()
                    : Botao(
                        texto: 'Concluir',
                        largura: 160,
                        altura: 45,
                        backgroundColor: Cores.azul,
                        textColor: Cores.branco,
                        onPressed: _salvarGasto,
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 0),
    );
  }
}
