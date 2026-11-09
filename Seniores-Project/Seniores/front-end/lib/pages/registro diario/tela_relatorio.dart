import 'package:flutter/material.dart';
import '../../models/registroDiario.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_bolinhas.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';
import 'tela_registroDiario.dart';
import 'tela_relatorioGrafico.dart';

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
      if (registros.isNotEmpty && mounted) {
        final ultimo = registros.first;

        setState(() {
          dadosRegistro = Registro.fromApiJson(ultimo);
          _temRegistro = true;
        });
      } else {
        dadosRegistro = Registro(humor: 0, dor: 0, apetite: 0, mobilidade: 0);
      }
    } catch (e) {
      _erro =
          e is ApiException ? e.message : 'Não foi possível carregar o diário.';
      dadosRegistro = Registro(humor: 0, dor: 0, apetite: 0, mobilidade: 0);
    } finally {
      if (mounted) setState(() => _carregando = false);
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
