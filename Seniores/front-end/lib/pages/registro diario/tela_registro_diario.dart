import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_barra_personalizada.dart';
import '../../widgets/custom_menu.dart';
import '../../models/incidente.dart';
import '../../models/registro_diario.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';

class RegistroDiario extends StatefulWidget {
  final Registro? registroParaEditar;

  const RegistroDiario({super.key, this.registroParaEditar});

  @override
  State<RegistroDiario> createState() => _RegistroDiarioState();
}

class _RegistroDiarioState extends State<RegistroDiario>
    with DraftState<RegistroDiario> {
  @override
  String get draftName => 'diario:${widget.registroParaEditar?.id ?? 'novo'}';
  @override
  Map<String, TextEditingController> get draftControllers => {
        'observacoesController': observacoesController,
        'incidenteDescricaoController': incidenteDescricaoController,
        'horarioController': horarioController,
        'duvidasController': duvidasController
      };

  @override
  Map<String, dynamic> get draftValues => {
        'incidenteTipoSelecionado': incidenteTipoSelecionado,
        'humor': humor,
        'dor': dor,
        'apetite': apetite,
        'mobilidade': mobilidade,
        'incidentes': listaIncidentes
            .map((i) => {
                  'titulo': i.titulo,
                  'hora': i.hora,
                  'descricao': i.descricao,
                  'gravidade': i.gravidade
                })
            .toList()
      };

  @override
  void restoreDraftValues(Map<String, dynamic> v) {
    if (v['incidentes'] is List) {
      listaIncidentes.clear();
      listaIncidentes.addAll((v['incidentes'] as List)
          .map((i) => Incidente.fromJson(Map<String, dynamic>.from(i))));
    }
    if (v['incidenteTipoSelecionado'] != null) {
      incidenteTipoSelecionado = v['incidenteTipoSelecionado'] as int;
    }
    if (v['humor'] != null) humor = (v['humor'] as num).toDouble();
    if (v['dor'] != null) dor = (v['dor'] as num).toDouble();
    if (v['apetite'] != null) apetite = (v['apetite'] as num).toDouble();
    if (v['mobilidade'] != null) {
      mobilidade = (v['mobilidade'] as num).toDouble();
    }
  }

  double humor = 0.0;
  double dor = 0.0;
  double apetite = 0.0;
  double mobilidade = 0.0;
  int incidenteTipoSelecionado = 0;

  final TextEditingController observacoesController = TextEditingController();
  final TextEditingController incidenteDescricaoController =
      TextEditingController();
  final TextEditingController horarioController =
      TextEditingController(text: "10:00");
  final TextEditingController duvidasController = TextEditingController();
  final List<Incidente> listaIncidentes = [];
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.registroParaEditar != null) {
      final r = widget.registroParaEditar!;
      // Normaliza os valores para 0.0 - 1.0 caso venham na escala 0 - 10
      humor = r.humor / 10.0;
      dor = r.dor / 10.0;
      apetite = r.apetite / 10.0;
      mobilidade = r.mobilidade / 10.0;

      observacoesController.text = r.observacoes ?? '';
      if (r.listaIncidentes != null) {
        listaIncidentes.addAll(r.listaIncidentes!);
      }
    }
  }

  Future<void> _salvarRegistro() async {
    final novoRegistro = Registro(
      humor: (humor * 10).round(),
      dor: (dor * 10).round(),
      apetite: (apetite * 10).round(),
      mobilidade: (mobilidade * 10).round(),
      listaIncidentes: List.from(listaIncidentes),
      tendencia: "Estável",
      dataFormatada: "Hoje",
      observacoes: observacoesController.text,
    );
    setState(() => _salvando = true);
    try {
      final dados = novoRegistro.toApiJson(duvidas: duvidasController.text);
      if (widget.registroParaEditar?.id != null) {
        await _apiService.atualizarRegistro(
            'diarios-saude', widget.registroParaEditar!.id!, dados);
      } else {
        await _apiService.criarDiario(dados);
      }
      await clearDraft();
      if (!mounted) return;
      Navigator.pop(context, novoRegistro);
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    saveDraftBeforeDispose();
    observacoesController.dispose();
    incidenteDescricaoController.dispose();
    horarioController.dispose();
    duvidasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: AppText(
                    texto: 'Registro diário',
                    tamanho: 24,
                    peso: FontWeight.bold,
                    cor: Theme.of(context).colorScheme.onSurface,
                  )),
                  IconButton(
                    icon: Icon(Icons.calendar_today_rounded,
                        color: Cores.azul, size: 28),
                    onPressed: () => showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()),
                  ),
                ],
              ),
              AppText(
                texto:
                    'Hoje, ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              SizedBox(height: 12),
              Divider(thickness: 1.5, color: Cores.cinza),
              SizedBox(height: 16),
              ItemNivelSaude(
                titulo: 'Humor',
                valor: humor,
                onChanged: (val) => setState(() => humor = val),
              ),
              ItemNivelSaude(
                titulo: 'Dor',
                valor: dor,
                inverso: true,
                onChanged: (val) => setState(() => dor = val),
              ),
              ItemNivelSaude(
                titulo: 'Apetite',
                valor: apetite,
                onChanged: (val) => setState(() => apetite = val),
              ),
              ItemNivelSaude(
                titulo: 'Mobilidade',
                valor: mobilidade,
                onChanged: (val) => setState(() => mobilidade = val),
              ),
              SizedBox(height: 20),
              AppText(
                texto: 'Observações',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              SizedBox(height: 8),
              CampoTexto(
                hintText: 'Digite aqui..',
                controller: observacoesController,
              ),
              SizedBox(height: 20),
              AppText(
                texto: 'Incidentes',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              SizedBox(height: 12),
              GrupoBotoes(
                itens: ['Incidente', 'Queda'],
                selecionado: incidenteTipoSelecionado,
                onSelecionado: (index) {
                  setState(() => incidenteTipoSelecionado = index);
                },
              ),
              SizedBox(height: 12),
              CampoTexto(
                hintText: 'Descrição..',
                controller: incidenteDescricaoController,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  AppText(
                    texto: 'Às',
                    tamanho: 14,
                    peso: FontWeight.bold,
                    cor: Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: CampoTexto(
                      hintText: '10:00',
                      controller: horarioController,
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Botao(
                      texto: 'Adicionar',
                      altura: 48,
                      borderRadius: 10,
                      onPressed: () {
                        if (incidenteDescricaoController.text.isNotEmpty) {
                          setState(() {
                            listaIncidentes.add(
                              Incidente(
                                titulo: incidenteTipoSelecionado == 0
                                    ? 'Incidente'
                                    : 'Queda',
                                hora: horarioController.text,
                                descricao: incidenteDescricaoController.text,
                                gravidade: 'Média',
                              ),
                            );
                            incidenteDescricaoController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(thickness: 1, color: Cores.cinza),
              SizedBox(height: 8),
              Column(
                children: listaIncidentes.map((incidente) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 14,
                                  fontFamily: 'Inter'),
                              children: [
                                TextSpan(
                                  text:
                                      '${incidente.titulo} às ${incidente.hora}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' - ${incidente.descricao}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              AppText(
                texto: 'Dúvidas para próxima consulta',
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: CampoTexto(
                  hintText: 'Digite aqui..',
                  controller: duvidasController,
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Botao(
                  texto: 'Concluir',
                  largura: 160,
                  altura: 45,
                  borderRadius: 12,
                  onPressed: _salvando ? () {} : _salvarRegistro,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 3),
    );
  }
}
