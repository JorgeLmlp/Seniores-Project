import 'package:flutter/material.dart';
import '../../models/exame.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import 'tela_adicionarExame.dart';
import 'tela_detalhesExames.dart';
import '../../services/api_service.dart';

class Exames extends StatefulWidget {
  const Exames({super.key});

  @override
  State<Exames> createState() => _TelaExamesState();
}

class _TelaExamesState extends State<Exames> {
  int _abaSelecionada = 0;

  final List<Exame> _todosExames = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final registros = await _apiService.listarRegistros('exames');
      if (mounted)
        setState(() => _todosExames.addAll(registros.map(Exame.fromRegistro)));
    } on ApiException catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

  Color _obterCorExame(Exame exame) {
    if (exame.concluido) {
      return Colors.grey;
    }

    final agora = DateTime.now();
    final diferenca = exame.dataHora.difference(agora);

    if (diferenca.inHours <= 3 && !diferenca.isNegative) {
      return Cores.vermelho;
    } else if (diferenca.inHours <= 8) {
      return Cores.amarelo;
    } else {
      return Cores.verde;
    }
  }

  @override
  Widget build(BuildContext context) {
    final examesFiltrados = _todosExames
        .where((e) => e.historico == (_abaSelecionada == 1))
        .toList();

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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 28,
                          color: Cores.preto,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const AppText(
                        texto: 'Exames',
                        estilo: AppText.titulo,
                        tamanho: 24,
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
              GrupoBotoes(
                itens: const ['Próximas', 'Histórico'],
                selecionado: _abaSelecionada,
                onSelecionado: (index) =>
                    setState(() => _abaSelecionada = index),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: examesFiltrados.length,
                itemBuilder: (context, index) {
                  final exame = examesFiltrados[index];
                  final corDestaque = _obterCorExame(exame);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _CardExameCustom(
                      exame: exame,
                      corTema: corDestaque,
                      onConcluir: () {
                        setState(() {
                          exame.concluido = !exame.concluido;
                        });
                      },
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
          final novoExame = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdicionarExame()),
          );
          if (novoExame != null && novoExame is Exame) {
            setState(() => _todosExames.add(novoExame));
          }
        },
        backgroundColor: Cores.azul,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}

class _CardExameCustom extends StatelessWidget {
  final Exame exame;
  final Color corTema;
  final VoidCallback onConcluir;

  const _CardExameCustom({
    required this.exame,
    required this.corTema,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final String dataFormatada =
        "${exame.dataHora.day.toString().padLeft(2, '0')}/${exame.dataHora.month.toString().padLeft(2, '0')}";
    final String horarioFormatado =
        "${exame.dataHora.hour.toString().padLeft(2, '0')}:00";

    return CardPadrao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(
                  texto: exame.nomeExame,
                  tamanho: 16,
                  peso: FontWeight.bold,
                  cor: corTema,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onConcluir,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: exame.concluido ? Colors.grey : corTema,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        exame.concluido ? 'Concluída' : 'Concluir',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    texto: dataFormatada,
                    tamanho: 12,
                    peso: FontWeight.bold,
                    cor: Cores.preto,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            texto: exame.local,
            tamanho: 12,
            cor: Colors.grey,
          ),
          const SizedBox(height: 12),
          if (!exame.historico) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText(
                    texto: horarioFormatado,
                    tamanho: 12,
                    peso: FontWeight.bold,
                    cor: corTema,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Botao(
                        texto: "Informações",
                        fontSize: 10,
                        altura: 30,
                        largura: 95,
                        backgroundColor: Colors.white,
                        textColor: corTema,
                        borderColor: corTema,
                        borderWidth: 1,
                        borderRadius: 20,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalhesExame(exame: exame),
                            ),
                          );
                        }),
                    const SizedBox(width: 6),
                    Icon(Icons.location_on_outlined, color: corTema, size: 20),
                  ],
                ),
              ],
            ),
          ] else ...[
            const Divider(height: 1, color: Cores.branco),
          ],
        ],
      ),
    );
  }
}
