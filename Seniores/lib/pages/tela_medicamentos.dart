import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_listas.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_botao.dart';
import '../models/medicamento.dart';
import 'tela_inicio.dart';
// import 'tela_detalhesRemedio.dart';
import 'tela_cadastroRemedio.dart';
import 'tela_detalhesMedicamento.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';

class Medicamentos extends StatefulWidget {
  final int? medicamentoId;

  const Medicamentos({super.key, this.medicamentoId});

  @override
  State<Medicamentos> createState() => _MedicamentosState();
}

class _MedicamentosState extends State<Medicamentos> {
  int abaSelecionada = 0;

  final List<Medicamento> _listaMedicamentos = [];
  bool carregando = true;
  String? erro;
  bool _medicamentoInicialAberto = false;

  // Mapeamento dos nomes das abas para filtrar a lista
  final List<String> _abasFrequencia = ["diario", "semanal", "mensal"];

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
  }

  Future<void> _carregarMedicamentos() async {
    try {
      final medicamentos = await ApiService().listarMedicamentos(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _listaMedicamentos
          ..clear()
          ..addAll(medicamentos);
        erro = null;
        carregando = false;
      });
      await NotificationService.sincronizar(medicamentos);
      final medicamentoInicial = widget.medicamentoId == null
          ? null
          : medicamentos
                .where((item) => item.id == widget.medicamentoId)
                .firstOrNull;
      if (medicamentoInicial != null && !_medicamentoInicialAberto) {
        _medicamentoInicialAberto = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _abrirDetalhes(medicamentoInicial);
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          erro = exception.message;
          carregando = false;
        });
      }
    } on StateError catch (exception) {
      if (mounted) {
        setState(() {
          erro = exception.message;
          carregando = false;
        });
      }
    }
  }

  Future<void> _abrirDetalhes(Medicamento item) async {
    final resultado = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDetalhesMedicamento(medicamento: item),
      ),
    );
    if (!mounted) return;
    if (resultado is Medicamento) {
      final indice = _listaMedicamentos.indexOf(item);
      if (indice >= 0) setState(() => _listaMedicamentos[indice] = resultado);
    } else if (resultado == true) {
      setState(() => _listaMedicamentos.remove(item));
    }
    await NotificationService.sincronizar(_listaMedicamentos);
  }

  @override
  Widget build(BuildContext context) {
    // Filtra os medicamentos baseados na aba/frequência selecionada
    final medicamentosFiltrados = _listaMedicamentos.where((m) {
      final abaAtual = _abasFrequencia[abaSelecionada].toLowerCase();
      return m.frequencia.toLowerCase() == abaAtual;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Título
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_double_arrow_left),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Home()),
                      );
                    },
                  ),
                  const SizedBox(width: 5),
                  const AppText(
                    texto: "Medicamento",
                    tamanho: 30,
                    peso: FontWeight.bold,
                    estilo: AppText.titulo,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Abas (Diários, Semanais, Mensais)
              GrupoBotoes(
                itens: const ["Diários", "Semanais", "Mensais"],
                selecionado: abaSelecionada,
                onSelecionado: (index) {
                  setState(() {
                    abaSelecionada = index;
                  });
                },
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Lista dinâmica de medicamentos
              Expanded(
                child: carregando
                    ? const Center(child: CircularProgressIndicator())
                    : erro != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(erro!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _carregarMedicamentos,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : medicamentosFiltrados.isEmpty
                    ? const Center(
                        child: AppText(
                          texto: "Nenhum medicamento cadastrado.",
                          tamanho: 14,
                          cor: Colors.grey,
                        ),
                      )
                    : ListView.builder(
                        itemCount: medicamentosFiltrados.length,
                        itemBuilder: (context, index) {
                          final item = medicamentosFiltrados[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListaPadrao(
                              titulo: item.nome,
                              subtitulo: item.descricaoSubtitulo,
                              textoBotao: "Detalhes",
                              onPressed: () async {
                                await _abrirDetalhes(item);
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

      // Botão Flutuante que aguarda o resultado do Cadastro
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF275DAD),
        onPressed: () async {
          // Abre a tela de cadastro e espera o retorno do novo Medicamento
          final novoMedicamento = await Navigator.push<Medicamento>(
            context,
            MaterialPageRoute(builder: (_) => const CadastroRemedio()),
          );

          // Se um novo medicamento foi retornado, adiciona à lista
          if (novoMedicamento != null) {
            try {
              final salvo = await ApiService().criarMedicamento(
                SessionService.instance.pacienteId,
                novoMedicamento,
              );
              final salvoComFoto =
                  novoMedicamento.fotoBytes == null ||
                      novoMedicamento.fotoNome == null
                  ? salvo
                  : await ApiService().enviarFotoMedicamento(
                      medicamentoId: salvo.id!,
                      nome: novoMedicamento.fotoNome!,
                      bytes: novoMedicamento.fotoBytes!,
                    );
              if (!mounted) return;
              setState(() {
                _listaMedicamentos.add(salvoComFoto);
              });
              await NotificationService.sincronizar(_listaMedicamentos);
            } on ApiException catch (exception) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(exception.message)));
            } on StateError catch (exception) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(exception.message)));
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: const Menu(paginaAtual: 1),
    );
  }
}
