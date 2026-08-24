import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_listas.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_botao.dart';
import '../models/medicamento.dart';
import '../utils/cores.dart';
import 'tela_inicio.dart';
import 'tela_cadastroRemedio.dart';
// import 'tela_detalhesRemedio.dart';
// import 'tela_cuidados.dart';
// import 'tela_notificacoes.dart';

class Medicamentos extends StatefulWidget {
  const Medicamentos({super.key});

  @override
  State<Medicamentos> createState() => _MedicamentosState();
}

class _MedicamentosState extends State<Medicamentos> {
  int abaSelecionada = 0;

  // estrutura da lista
  final List<Medicamento> _listaMedicamentos = [
    Medicamento(
      nome: "Dipirona 500mg",
      dosagem: "1 comprimido - 3 vezes ao dia",
      frequencia: "diário",
      horarios: ["08:00", "14:00", "20:00"],
    ),
  ];

  final List<String> _abasFrequencia = ["diário", "Semanal", "Mensal"];

  @override
  Widget build(BuildContext context) {
    final medicamentosFiltrados = _listaMedicamentos.where((m) {
      final abaAtual = _abasFrequencia[abaSelecionada].toLowerCase();
      return m.frequencia.toLowerCase() == abaAtual;
    }).toList();

    return Scaffold(
      backgroundColor: Cores.branco,
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
                    icon: const Icon(Icons.keyboard_double_arrow_left, color: Cores.preto),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Home(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 5),
                  const AppText(
                    texto: "Medicamento",
                    peso: FontWeight.bold,
                    estilo: AppText.titulo,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              GrupoBotoes(
                itens: const ["Diários","Semanais","Mensais"],
                selecionado: abaSelecionada,
                onSelecionado: (index) {
                  setState(() {
                    abaSelecionada = index;
                  });
                },
              ),

              const SizedBox(height: 20),
              const Divider(color: Cores.cinza),
              const SizedBox(height: 10),

              Expanded(
                child: medicamentosFiltrados.isEmpty
                    ? const Center(
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
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListaPadrao(
                              titulo: item.nome,
                              subtitulo: item.descricaoSubtitulo,
                              textoBotao: "Detalhes",
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
              builder: (_) => const CadastroRemedio(),
            ),
          );

          if (novoMedicamento != null) {
            setState(() {
              _listaMedicamentos.add(novoMedicamento);
            });
          }
        },
        child: const Icon(Icons.add, color: Cores.branco),
      ),

      bottomNavigationBar: const Menu(
        paginaAtual: 1,
      ),
    );
  }
}