import 'package:flutter/material.dart';
import '../../models/registro_diario.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_bolinhas.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import 'tela_registro_diario.dart';
import 'tela_relatorio_grafico.dart';

class Relatorio extends StatefulWidget {
  final Registro? registro;

  const Relatorio({
    super.key,
    this.registro,
  });

  @override
  State<Relatorio> createState() => _RelatorioState();
}

class _RelatorioState extends State<Relatorio> {
  late Registro dadosRegistro;
  bool _carregando = true;
  bool _temRegistro = false;
  List<Map<String, dynamic>> _historico = [];
  DateTimeRange? _periodo;
  int? _idSelecionado;

  String? _erro;
  final ApiService _apiService =
      ApiService(); // Certifique-se de importar o api_service.dart

  @override
  void initState() {
    super.initState();
    if (widget.registro != null) {
      dadosRegistro = widget.registro!;
      _temRegistro = true;
      _carregando = false;
    } else {
      _carregarUltimoRegistro();
    }
  }

  Future<void> _carregarUltimoRegistro() async {
    try {
      final registros = await _apiService.listarDiarios();
      registros.sort((a, b) => '${b['data_criacao'] ?? ''}'.compareTo('${a['data_criacao'] ?? ''}'));
      if (!mounted) return;
      setState(() {
        _historico = registros;
        if (registros.isNotEmpty) {
          final item = registros.firstWhere(
            (r) => r['id'] == _idSelecionado, orElse: () => registros.first);
          dadosRegistro = Registro.fromApiJson(item);
          _idSelecionado = dadosRegistro.id;
          _temRegistro = true;
        } else {
          _temRegistro = false;
          dadosRegistro = Registro(humor: 0, dor: 0, apetite: 0, mobilidade: 0);
        }
      });
    } catch (e) {
      _erro =
          e is ApiException ? e.message : 'Não foi possível carregar o diário.';
      dadosRegistro = Registro(humor: 0, dor: 0, apetite: 0, mobilidade: 0);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirHistorico() async {
    if (_historico.isEmpty) await _carregarUltimoRegistro();
    if (!mounted) return;
    final intervalo = await showDateRangePicker(context: context,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      initialDateRange: _periodo);
    if (!mounted || intervalo == null) return;
    setState(() => _periodo = intervalo);
    final candidatos = _historico.where((r) {
      final d = DateTime.tryParse('${r['data_criacao'] ?? ''}');
      return d != null && !d.isBefore(DateTime(intervalo.start.year, intervalo.start.month, intervalo.start.day))
          && d.isBefore(DateTime(intervalo.end.year, intervalo.end.month, intervalo.end.day + 1));
    }).toList();
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (modalContext) => SafeArea(child: SizedBox(height: 430, child: Column(children: [
        const ListTile(title: Text('Registros do período')),
        if (candidatos.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Nenhum registro nesse período.')),
        Expanded(child: ListView(children: candidatos.map((item) => ListTile(
          title: Text(Registro.fromApiJson(item).dataFormatada ?? 'Sem data'),
          subtitle: Text('${item['descricao'] ?? ''}', maxLines: 1),
          onTap: () {
            setState(() {
              dadosRegistro = Registro.fromApiJson(item);
              _idSelecionado = dadosRegistro.id;
            });
            Navigator.pop(modalContext);
          },
        )).toList())),
      ]))));
  }

  Future<void> _excluirSelecionado() async {
    final id = dadosRegistro.id;
    if (id == null) return;
    final confirmou = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir registro do diário?'),
      content: const Text('Essa ação não poderá ser desfeita.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir'))]));
    if (confirmou != true) return;
    try {
      await _apiService.excluirRegistro('diarios-saude', id);
      _idSelecionado = null;
      await _carregarUltimoRegistro();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Erro ao excluir o registro.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregando && (!_temRegistro || _erro != null)) {
      return Scaffold(
          appBar: AppBar(title: const Text('Diário de saúde')),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_erro ??
                        'Nenhum diário registrado para este paciente.'),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () async {
                          if (_erro == null) {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegistroDiario()));
                          }
                          if (!mounted) return;
                          setState(() {
                            _carregando = true;
                            _erro = null;
                          });
                          await _carregarUltimoRegistro();
                        },
                        child: Text(_erro == null
                            ? 'Adicionar registro'
                            : 'Tentar novamente')),
                  ]))),
          bottomNavigationBar: const Menu(paginaAtual: 3));
    }
    if (_carregando) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () =>
                              Navigator.pop(context, dadosRegistro),
                        ),
                        Text(
                          'Relatório',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      OutlinedButton.icon(onPressed: _abrirHistorico,
                        icon: const Icon(Icons.history), label: const Text('Histórico por período')),
                      OutlinedButton.icon(onPressed: _excluirSelecionado,
                        icon: const Icon(Icons.delete_outline), label: const Text('Excluir registro')),
                    ]),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ' ${dadosRegistro.dataFormatada ?? "Hoje"}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Cores.azul,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Cores.azul,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today,
                              color: Cores.branco, size: 18),
                        ),
                      ],
                    ),
                    Divider(thickness: 1, height: 24, color: Cores.cinza),
                    BarraIndicador(
                        label: 'Humor', valor: dadosRegistro.humor.toDouble()),
                    BarraIndicador(
                        label: 'Dor',
                        valor: dadosRegistro.dor.toDouble(),
                        inverso: true),
                    BarraIndicador(
                        label: 'Apetite',
                        valor: dadosRegistro.apetite.toDouble()),
                    BarraIndicador(
                        label: 'Mobilidade',
                        valor: dadosRegistro.mobilidade.toDouble()),
                    SizedBox(height: 16),
                    Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Cores.azul,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      (dadosRegistro.observacoes != null &&
                              dadosRegistro.observacoes!.isNotEmpty)
                          ? dadosRegistro.observacoes!
                          : 'Sem observações registradas.',
                      style: TextStyle(color: Cores.cinza, fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Incidentes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Cores.azul,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (dadosRegistro.listaIncidentes != null &&
                        dadosRegistro.listaIncidentes!.isNotEmpty)
                      ...dadosRegistro.listaIncidentes!
                          .map((incidente) => Padding(
                                padding: EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: incidente.gravidade == 'Alta'
                                          ? Cores.vermelho
                                          : Cores.amarelo,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${incidente.titulo} às ${incidente.hora} ${incidente.descricao}',
                                        style: TextStyle(
                                          color: incidente.gravidade == 'Alta'
                                              ? Cores.vermelho
                                              : Cores.preto,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                    else
                      Text(
                        'Nenhum incidente registrado hoje.',
                        style: TextStyle(color: Cores.cinza, fontSize: 13),
                      ),
                    SizedBox(height: 20),
                    Center(
                      child: Botao(
                        texto: 'Editar',
                        icone: Icons.edit_note,
                        largura: 150,
                        altura: 45,
                        fontSize: 14,
                        backgroundColor: Cores.azul,
                        textColor: Cores.branco,
                        onPressed: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistroDiario(
                                  registroParaEditar: dadosRegistro),
                            ),
                          );

                          if (resultado != null && resultado is Registro) {
                            setState(() {
                              dadosRegistro = resultado;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tendência',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Cores.azul,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.trending_down,
                                    color: Cores.vermelho, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  dadosRegistro.tendencia ?? 'Estável',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Cores.azul,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RelatorioGrafico(),
                              ),
                            );
                          },
                          child: Text('Ver relatório',
                              style: TextStyle(color: Cores.branco)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 3),
    );
  }
}
