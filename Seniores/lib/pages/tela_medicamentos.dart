
import 'package:flutter/material.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_listas.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_botao.dart';
import '../models/medicamento.dart';
import 'tela_inicio.dart';
// import 'tela_detalhesRemedio.dart';
import 'tela_cadastroRemedio.dart';
// import 'tela_cuidados.dart';
// import 'tela_diarioSaude.dart';
// import 'tela_notificacoes.dart';

class Medicamentos extends StatefulWidget {
  const Medicamentos({super.key});

  @override
  State<Medicamentos> createState() => _MedicamentosState();
}

class _MedicamentosState extends State<Medicamentos> {
  int abaSelecionada = 0;

//Demonstracao
  final List<Medicamento> _listaMedicamentos = [
    Medicamento(
      nome: "Dipirona 500mg",
      dosagem: "1 comprimido - 3 vezes ao dia",
      frequencia: "diário",
      horarios: ["08:00", "14:00", "20:00"],
    ),
  ];

  // Mapeamento dos nomes das abas para filtrar a lista
  final List<String> _abasFrequencia = ["diário", "Semanal", "Mensal"];

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
                        MaterialPageRoute(
                          builder: (_) => const Home(),
                        ),
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
                itens: const [
                  "Diários",
                  "Semanais",
                  "Mensais",
                ],
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
                child: medicamentosFiltrados.isEmpty
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
            MaterialPageRoute(
              builder: (_) => const CadastroRemedio(),
            ),
          );

          // Se um novo medicamento foi retornado, adiciona à lista
          if (novoMedicamento != null) {
            setState(() {
              _listaMedicamentos.add(novoMedicamento);
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: const Menu(
        paginaAtual: 1,
      ),
    );
  }
}