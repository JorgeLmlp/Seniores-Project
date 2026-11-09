import 'tela_adicionar_consulta.dart';
import 'package:flutter/material.dart';
import 'package:widgets/pages/cuidados/tela_detalhes_consulta.dart';
import 'package:widgets/pages/cuidados/tela_detalhes_exames.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_listas.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../models/consulta.dart';
import '../../models/exame.dart';
import 'tela_consultas.dart';
import 'tela_exames.dart';
import '../../services/api_service.dart';

class Cuidados extends StatefulWidget {
  const Cuidados({super.key});

  @override
  State<Cuidados> createState() => _CuidadosState();
}

class _CuidadosState extends State<Cuidados> {
  final ApiService _apiService = ApiService();
  List<Consulta> _consultasRecentes = [];
  List<Exame> _examesRecentes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final resConsultas = await _apiService.listarRegistros('consultas');
      final resExames = await _apiService.listarRegistros('exames');

      if (mounted) {
        setState(() {
          final todasConsultas =
              resConsultas.map(Consulta.fromRegistro).toList();
          final todosExames = resExames.map(Exame.fromRegistro).toList();

          _consultasRecentes = todasConsultas.take(2).toList();
          _examesRecentes = todosExames.take(2).toList();
        });
      }
    } catch (_) {}
  }

  Color _obterCorPorTempo(DateTime dataHora, bool concluido) {
    if (concluido) return Colors.grey;

    final agora = DateTime.now();
    final diferencaMinutos = dataHora.difference(agora).inMinutes;

    if (diferencaMinutos < 0) {
      return Cores.vermelho; // Passou do horário
    } else if (diferencaMinutos <= 60) {
      return Cores.amarelo; // Perto (<= 1h)
    } else {
      return Cores.azul; // Longe
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
                  Expanded(
                      child: AppText(
                    texto: 'Exames e Consultas',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  )),
                ],
              ),
              SizedBox(height: 20),
              ListaComCard(
                tituloCard: "Consultas",
                itens: [
                  if (_consultasRecentes.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Nenhuma consulta cadastrada.",
                          style: TextStyle(color: Cores.cinza)),
                    )
                  else
                    ..._consultasRecentes.map((consulta) {
                      final corDestaque = _obterCorPorTempo(
                          consulta.dataHora, consulta.concluida);
                      final dataFmt =
                          "${consulta.dataHora.day.toString().padLeft(2, '0')}/${consulta.dataHora.month.toString().padLeft(2, '0')}";
                      final horaFmt =
                          "${consulta.dataHora.hour.toString().padLeft(2, '0')}:00";
                      return ListaSemCard(
                        titulo: "${consulta.nomeDoutor} ($dataFmt)",
                        subtitulo: "${consulta.especialidade} às $horaFmt",
                        textoBotao: "Informações",
                        corIndicador: corDestaque,
                        corBotao: corDestaque,
                        // Navega para a tela de Detalhes da Consulta passando o objeto correspondente
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalhesConsulta(consulta: consulta),
                            ),
                          );
                        },
                      );
                    }),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Botao(
                            texto: 'Mais detalhes',
                            altura: 38,
                            fontSize: 12,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            textColor: Cores.azul,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Consultas(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Botao(
                            texto: 'Consulta Fácil',
                            altura: 38,
                            fontSize: 12,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            textColor: Cores.azul,
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdicionarConsulta())),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ListaComCard(
                tituloCard: "Exames",
                itens: [
                  if (_examesRecentes.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Nenhum exame cadastrado.",
                          style: TextStyle(color: Cores.cinza)),
                    )
                  else
                    ..._examesRecentes.map((exame) {
                      final corDestaque =
                          _obterCorPorTempo(exame.dataHora, exame.concluido);
                      final dataFmt =
                          "${exame.dataHora.day.toString().padLeft(2, '0')}/${exame.dataHora.month.toString().padLeft(2, '0')}";
                      final horaFmt =
                          "${exame.dataHora.hour.toString().padLeft(2, '0')}:00";
                      return ListaSemCard(
                        titulo: "${exame.nomeExame} ($dataFmt)",
                        subtitulo: "${exame.local} às $horaFmt",
                        textoBotao: "Informações",
                        corIndicador: corDestaque,
                        corBotao: corDestaque,
                        // Navega para a tela de Detalhes do Exame passando o objeto correspondente
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalhesExame(exame: exame),
                            ),
                          );
                        },
                      );
                    }),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Botao(
                        texto: 'Mais detalhes',
                        largura: 160,
                        altura: 38,
                        fontSize: 12,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        textColor: Cores.azul,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Exames(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 2),
    );
  }
}
