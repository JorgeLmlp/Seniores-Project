import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_menu.dart';
import '../../models/medicamento.dart';
import '../../utils/cores.dart';
import '../../services/api_service.dart';

class CadastroRemedio extends StatefulWidget {
  final Medicamento? medicamento;
  const CadastroRemedio({super.key, this.medicamento});

  @override
  State<CadastroRemedio> createState() => _CadastroRemedioState();
}

class _CadastroRemedioState extends State<CadastroRemedio>
    with DraftState<CadastroRemedio> {
  @override
  Map<String, TextEditingController> get draftControllers => {
        '_nomeController': _nomeController,
        '_dosagemController': _dosagemController,
        '_alertaController': _alertaController
      };

  @override
  Map<String, dynamic> get draftValues => {
        'frequenciaSelecionada': frequenciaSelecionada,
        '_alertas': _alertas,
        '_horarios': _horarios
      };

  @override
  void restoreDraftValues(Map<String, dynamic> v) {
    if (v['frequenciaSelecionada'] != null) {
      frequenciaSelecionada = v['frequenciaSelecionada'] as int;
    }
    if (v['_alertas'] is List) {
      _alertas.clear();
      _alertas.addAll((v['_alertas'] as List).cast<String>());
    }
    if (v['_horarios'] is List) {
      _horarios.clear();
      _horarios.addAll((v['_horarios'] as List).cast<String>());
    }
  }

  @override
  String get draftName => 'medicamento:${widget.medicamento?.id ?? 'novo'}';

  int frequenciaSelecionada = 0;

  final List<String> opcoesFrequencia = ["diário", "Semanal", "Mensal"];
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dosagemController = TextEditingController();
  final TextEditingController _alertaController = TextEditingController();
  final List<String> _horarios = [];
  final List<String> _alertas = [];
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final med = widget.medicamento;
    if (med != null) {
      _nomeController.text = med.nome;
      _dosagemController.text = med.dosagem;
      _horarios.addAll(med.horarios);
      _alertas.addAll(med.alertas);
      final index = opcoesFrequencia.indexOf(med.frequencia);
      frequenciaSelecionada = index < 0 ? 0 : index;
    }
  }

  @override
  void dispose() {
    saveDraftBeforeDispose();
    _nomeController.dispose();
    _dosagemController.dispose();
    _alertaController.dispose();
    super.dispose();
  }

  Future<void> _salvarMedicamento() async {
    if (_nomeController.text.trim().isEmpty ||
        _dosagemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informe o nome e a dosagem do medicamento.')),
      );
      return;
    }

    final novoMedicamento = Medicamento(
      nome: _nomeController.text.trim(),
      dosagem: _dosagemController.text.trim(),
      frequencia: opcoesFrequencia[frequenciaSelecionada],
      horarios: List.from(_horarios),
      alertas: List.from(_alertas),
    );

    setState(() => _salvando = true);
    try {
      final salvo = widget.medicamento?.id == null
          ? await _apiService.criarMedicamento(novoMedicamento.toJson())
          : await _apiService.requisicao(
              'PATCH', '/medicamentos/${widget.medicamento!.id}',
              dados: novoMedicamento.toJson()) as Map<String, dynamic>;
      await clearDraft();
      if (mounted) Navigator.pop(context, Medicamento.fromJson(salvo));
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Menu(paginaAtual: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
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
                    texto: "Adicionar medicamento",
                    tamanho: 22,
                    peso: FontWeight.bold,
                    estilo: AppText.titulo,
                  )),
                ],
              ),
              SizedBox(height: 25),
              AppText(
                texto: "Nome do medicamento",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),
              SizedBox(height: 8),
              CampoTexto(
                hintText: "Digite aqui...",
                controller: _nomeController,
              ),
              SizedBox(height: 20),
              AppText(
                texto: "Frequencia",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),
              SizedBox(height: 8),
              GrupoBotoes(
                itens: opcoesFrequencia,
                selecionado: frequenciaSelecionada,
                onSelecionado: (index) {
                  setState(() {
                    frequenciaSelecionada = index;
                  });
                },
              ),
              SizedBox(height: 20),
              AppText(
                texto: "Horarios",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? horaSelecionada = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );

                      if (horaSelecionada != null) {
                        final horarioFormatado =
                            "${horaSelecionada.hour.toString().padLeft(2, '0')}:${horaSelecionada.minute.toString().padLeft(2, '0')}";

                        if (!_horarios.contains(horarioFormatado)) {
                          setState(() {
                            _horarios.add(horarioFormatado);
                            _horarios.sort();
                          });
                        }
                      }
                    },
                    child: Container(
                      width: 45,
                      height: 38,
                      decoration: BoxDecoration(
                        border: Border.all(color: Cores.cinza),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add, color: Cores.cinza),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _horarios.map((horario) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Cores.cinza),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                horario,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _horarios.remove(horario);
                                  });
                                },
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              AppText(
                texto: "Dosagem",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),
              SizedBox(height: 8),
              CampoTexto(
                hintText: "Digite aqui...",
                controller: _dosagemController,
              ),
              SizedBox(height: 20),
              AppText(
                texto: "Alertas",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Cores.azul,
                estilo: AppText.subtitulo,
              ),
              SizedBox(height: 8),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CampoTexto(
                    hintText: "Digite aqui...",
                    controller: _alertaController,
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Cores.cinza),
                    onPressed: () {
                      if (_alertaController.text.trim().isNotEmpty) {
                        setState(() {
                          _alertas.add(_alertaController.text.trim());
                          _alertaController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _alertas.map((alerta) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Cores.cinza),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alerta,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              Center(
                child: Botao(
                  texto: "Concluir",
                  largura: 160,
                  altura: 45,
                  borderRadius: 12,
                  backgroundColor: Cores.azul,
                  textColor: Cores.branco,
                  onPressed: _salvando ? () {} : _salvarMedicamento,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
