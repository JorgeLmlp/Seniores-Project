import 'package:flutter/material.dart';
import '../../models/consulta.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import 'tela_adicionarConsulta.dart';
import 'tela_detalhesConsulta.dart';
import '../../services/api_service.dart';

class Consultas extends StatefulWidget {
  const Consultas({super.key});

  @override
  State<Consultas> createState() => _TelaConsultasState();
}

class _TelaConsultasState extends State<Consultas> {
  int _abaSelecionada = 0;

  final List<Consulta> _todasConsultas = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final registros = await _apiService.listarRegistros('consultas');
      if (mounted)
        setState(
            () => _todasConsultas.addAll(registros.map(Consulta.fromRegistro)));
    } on ApiException catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

  Color _obterCorConsulta(Consulta consulta) {
    if (consulta.concluida) {
      return Colors.grey;
    }

    final agora = DateTime.now();
    final diferenca = consulta.dataHora.difference(agora);

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
    final consultasFiltradas = _todasConsultas
        .where((c) => c.historico == (_abaSelecionada == 1))
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
                        texto: 'Consultas',
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
                itemCount: consultasFiltradas.length,
                itemBuilder: (context, index) {
                  final consulta = consultasFiltradas[index];
                  final corDestaque = _obterCorConsulta(consulta);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _CardConsultaCustom(
                      consulta: consulta,
                      corTema: corDestaque,
                      onConcluir: () {
                        setState(() {
                          consulta.concluida = !consulta.concluida;
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
          final novaConsulta = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdicionarConsulta(),
            ),
          );

          if (novaConsulta != null && novaConsulta is Consulta) {
            setState(() {
              _todasConsultas.add(novaConsulta);
            });
          }
        },
        backgroundColor: Cores.azul,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}

class _CardConsultaCustom extends StatelessWidget {
  final Consulta consulta;
  final Color corTema;
  final VoidCallback onConcluir;

  const _CardConsultaCustom({
    required this.consulta,
    required this.corTema,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final String dataFormatada =
        "${consulta.dataHora.day.toString().padLeft(2, '0')}/${consulta.dataHora.month.toString().padLeft(2, '0')}";
    final String horarioFormatado =
        "${consulta.dataHora.hour.toString().padLeft(2, '0')}:00";

    return CardPadrao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(
                  texto: consulta.nomeDoutor,
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
                        color: consulta.concluida ? Colors.grey : corTema,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        consulta.concluida ? 'Concluída' : 'Concluir',
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
            texto: consulta.especialidade,
            tamanho: 12,
            cor: Colors.grey,
          ),
          const SizedBox(height: 12),
          if (!consulta.historico) ...[
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
                            builder: (_) =>
                                DetalhesConsulta(consulta: consulta),
                          ),
                        );
                      },
                    ),
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
