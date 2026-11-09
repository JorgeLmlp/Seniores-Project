import 'package:flutter/material.dart';
import '../../models/exame.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import 'tela_adicionar_exame.dart';
import 'tela_detalhes_exames.dart';

class Exames extends StatefulWidget {
  const Exames({super.key, this.registroDestaque});
  final String? registroDestaque;

  @override
  State<Exames> createState() => _TelaExamesState();
}

class _TelaExamesState extends State<Exames> {
  bool _destaqueAberto = false;
  int _abaSelecionada = 0; // 0: Próximas, 1: Histórico

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
      if (mounted) {
        setState(() {
          _todosExames.clear();
          _todosExames.addAll(registros.map(Exame.fromRegistro));
        });
        if (!_destaqueAberto && widget.registroDestaque != null) {
          _destaqueAberto = true;
          final candidatos = _todosExames.where((r) => r.id == widget.registroDestaque);
          if (candidatos.isNotEmpty) {
            final registro = candidatos.first;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => DetalhesExame(exame: registro)));
              if (mounted) await _carregar();
            });
          }
        }
      }
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
      }
    }
  }

  Color _obterCorExame(Exame exame) {
    if (exame.historico || exame.concluido) {
      return Colors.grey;
    }

    final agora = DateTime.now();
    final diferencaMinutos = exame.dataHora.difference(agora).inMinutes;

    if (diferencaMinutos < 0) {
      return Cores.vermelho;
    } else if (diferencaMinutos <= 60) {
      return Cores.amarelo;
    } else {
      return Cores.azul;
    }
  }

  final Set<String> _atualizando = {};
  Future<void> _alternarConclusao(Exame exame) async {
    if (!_atualizando.add(exame.id)) return;
    final novo = !exame.concluido;
    try {
      await _apiService.atualizarRegistro(
          'exames', exame.id, {'concluido': novo, 'historico': novo});
      if (mounted) {
        setState(() {
          exame.concluido = novo;
          exame.historico = novo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                e is ApiException ? e.message : 'Falha ao salvar o status.')));
      }
    } finally {
      _atualizando.remove(exame.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final examesFiltrados = _todosExames
        .where((e) => e.historico == (_abaSelecionada == 1))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
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
                        texto: 'Exames',
                        estilo: AppText.titulo,
                        tamanho: 24,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Cores.azul),
                    onPressed: _carregar,
                  ),
                ],
              ),
              SizedBox(height: 20),
              GrupoBotoes(
                itens: ['Próximas', 'Histórico'],
                selecionado: _abaSelecionada,
                onSelecionado: (index) =>
                    setState(() => _abaSelecionada = index),
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: examesFiltrados.length,
                itemBuilder: (context, index) {
                  final exame = examesFiltrados[index];
                  final corDestaque = _obterCorExame(exame);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: _CardExameCustom(
                      exame: exame,
                      corTema: corDestaque,
                      onConcluir: () => _alternarConclusao(exame),
                      onAtualizar: _carregar,
                    ),
                  );
                },
              ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final novoExame = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdicionarExame()),
          );
          if (!mounted) return;
          if (novoExame is Exame) {
            setState(() => _todosExames.insert(0, novoExame));
          }
          // Sincroniza com o backend após retornar do cadastro.
          await _carregar();
        },
        backgroundColor: Cores.azul,
        child: Icon(Icons.add, color: Cores.branco),
      ),
      bottomNavigationBar: Menu(paginaAtual: 2),
    );
  }
}

class _CardExameCustom extends StatelessWidget {
  final Exame exame;
  final Color corTema;
  final VoidCallback onConcluir;
  final VoidCallback onAtualizar;

  const _CardExameCustom({
    required this.exame,
    required this.corTema,
    required this.onConcluir,
    required this.onAtualizar,
  });

  @override
  Widget build(BuildContext context) {
    final String dataFormatada =
        "${exame.dataHora.day.toString().padLeft(2, '0')}/${exame.dataHora.month.toString().padLeft(2, '0')}";
    final String horarioFormatado =
        "${exame.dataHora.hour.toString().padLeft(2, '0')}:${exame.dataHora.minute.toString().padLeft(2, '0')}";

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
              SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onConcluir,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: exame.concluido ? Colors.grey : corTema,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        exame.concluido ? 'Concluída' : 'Concluir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  AppText(
                    texto: dataFormatada,
                    tamanho: 12,
                    peso: FontWeight.bold,
                    cor: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          AppText(
            texto: exame.local,
            tamanho: 12,
            cor: Colors.grey,
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: Cores.branco),
          SizedBox(height: 12),
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
              SizedBox(width: 8),
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
                    onPressed: () async {
                      final mudou = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => DetalhesExame(exame: exame)),
                      );
                      if (mudou == true) onAtualizar();
                    },
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.location_on_outlined, color: corTema, size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
