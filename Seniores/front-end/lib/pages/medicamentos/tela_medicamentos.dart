import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_listas.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../models/medicamento.dart';
import '../../utils/cores.dart';
import 'tela_cadastro_remedio.dart';
import 'tela_detalhes_medicamento.dart';
import '../../services/api_service.dart';

class Medicamentos extends StatefulWidget {
  const Medicamentos({super.key, this.registroDestaque});
  final int? registroDestaque;

  @override
  State<Medicamentos> createState() => _MedicamentosState();
}

class _MedicamentosState extends State<Medicamentos> {
  int abaSelecionada = 0;
  bool _carregando = true;
  bool _destaqueAberto = false;
  String? _erro;

  final List<Medicamento> _listaMedicamentos = [];
  final ApiService _apiService = ApiService();

  final List<String> _abasFrequencia = ["diário", "Semanal", "Mensal"];

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
  }

  Future<void> _carregarMedicamentos() async {
    try {
      final dados = await _apiService.listarMedicamentos();
      if (!mounted) return;
      setState(() {
        _listaMedicamentos
          ..clear()
          ..addAll(dados.map(Medicamento.fromJson))
          ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        _erro = null;
      });
      if (!_destaqueAberto && widget.registroDestaque != null) {
        _destaqueAberto = true;
        final candidatos = _listaMedicamentos.where((m) => m.id == widget.registroDestaque);
        if (candidatos.isNotEmpty) {
          final med = candidatos.first;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => DetalhesMedicamento(medicamento: med)));
            if (mounted) await _carregarMedicamentos();
          });
        }
      }
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicamentosFiltrados = _listaMedicamentos.where((m) {
      final abaAtual = _abasFrequencia[abaSelecionada].toLowerCase();
      return m.frequencia.toLowerCase() == abaAtual;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  AppText(
                    texto: 'Medicamentos',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 20),
              GrupoBotoes(
                itens: ["Diários", "Semanais", "Mensais"],
                selecionado: abaSelecionada,
                onSelecionado: (index) {
                  setState(() {
                    abaSelecionada = index;
                  });
                },
              ),
              SizedBox(height: 20),
              Divider(color: Cores.cinza),
              SizedBox(height: 10),
              Expanded(
                child: _carregando
                    ? Center(child: CircularProgressIndicator())
                    : _erro != null
                        ? Center(
                            child: Text(_erro!, textAlign: TextAlign.center))
                        : medicamentosFiltrados.isEmpty
                            ? Center(
                                child: AppText(
                                  texto: "Nenhum medicamento cadastrado.",
                                  tamanho: 14,
                                  cor: Cores.cinza,
                                ),
                              )
                            : ListView.builder(
                                itemCount: medicamentosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final item = medicamentosFiltrados[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: ListaSemCard(
                                      titulo: item.nome,
                                      subtitulo: item.descricaoSubtitulo,
                                      textoBotao: "Detalhes",
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetalhesMedicamento(
                                              medicamento: item,
                                            ),
                                          ),
                                        );
                                        if (mounted) {
                                          await _carregarMedicamentos();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Cores.azul,
        onPressed: () async {
          final novoMedicamento = await Navigator.push<Medicamento>(
            context,
            MaterialPageRoute(
              builder: (_) => CadastroRemedio(),
            ),
          );

          if (novoMedicamento != null) {
            setState(() {
              _listaMedicamentos.insert(0, novoMedicamento);
              abaSelecionada = _abasFrequencia.indexWhere((f) =>
                f.toLowerCase() == novoMedicamento.frequencia.toLowerCase());
              if (abaSelecionada < 0) abaSelecionada = 0;
            });
          }
        },
        child: Icon(Icons.add, color: Cores.branco),
      ),
      bottomNavigationBar: Menu(
        paginaAtual: 1,
      ),
    );
  }
}
