import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import '../../utils/mascaras.dart';

class NovoGasto extends StatefulWidget {
  const NovoGasto({super.key});

  @override
  State<NovoGasto> createState() => _NovoGastoScreenState();
}

class _NovoGastoScreenState extends State<NovoGasto> {
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
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvarGasto() async {
    final nome = _nomeController.text.trim();
    final valorTexto = _valorController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome da categoria.')),
      );
      return;
    }

    final digitsOnly = valorTexto.replaceAll(RegExp(r'\D'), '');
    final valor = digitsOnly.isEmpty ? 0.0 : double.parse(digitsOnly) / 100;

    setState(() => _salvando = true);

    try {
      await _apiService.criarRegistro('gastos', {
        'nome': nome,
        'categoria': nome,
        'valor': valor,
        'tipo': _tipoSelecionado,
        'cor': _corSelecionada,
      });

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
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  const AppText(texto: 'Novo gasto', estilo: AppText.titulo, tamanho: 24, peso: FontWeight.bold),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Nome da Categoria / Gasto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Cores.preto)),
              const SizedBox(height: 8),
              
              CampoTexto(
                hintText: "Ex: Farmácia, Consultas...",
                controller: _nomeController,
              ),
              
              const SizedBox(height: 20),
              const Text("Valor (R\$)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Cores.preto)),
              const SizedBox(height: 8),
              
              CampoTexto(
                hintText: "0,00",
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [DinheiroInputFormatter()],
              ),

              const SizedBox(height: 20),
              const Text("Tipo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Cores.preto)),
              const SizedBox(height: 8),
              Row(
                children: ['Mensal', 'Anual'].map((tipo) {
                  bool selecionado = _tipoSelecionado == tipo;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selecionado ? Cores.azul : Cores.branco,
                          side: const BorderSide(color: Cores.azul),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => setState(() => _tipoSelecionado = tipo),
                        child: Text(tipo, style: TextStyle(color: selecionado ? Cores.branco : Cores.azul, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text("Cor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Cores.preto)),
              const SizedBox(height: 8),
              
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
                        border: selecionado ? Border.all(color: Cores.preto, width: 3) : null,
                      ),
                      child: selecionado ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
              Center(
                child: _salvando
                    ? const CircularProgressIndicator()
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
            bottomNavigationBar: const Menu(paginaAtual: 0),
          );
        }
      }