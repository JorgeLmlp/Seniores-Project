import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_text_field.dart';
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
  Uint8List? _fotoSelecionada;
  String? _fotoMime;
  bool _removerFoto = false;

  Future<void> _selecionarFoto(ImageSource origem) async {
    try {
      final imagem = await ImagePicker().pickImage(source: origem,
        maxWidth: 1400, imageQuality: 80);
      if (imagem == null) return;
      final bytes = await imagem.readAsBytes();
      if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
        throw ApiException('Escolha uma foto de até 2 MB.');
      }
      final ext = imagem.name.split('.').last.toLowerCase();
      final tipo = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
        'png': 'image/png', 'webp': 'image/webp'}[ext];
      if (tipo == null) throw ApiException('Somente JPG, PNG ou WebP.');
      if (mounted) {
        setState(() {
          _fotoSelecionada = bytes; _fotoMime = tipo; _removerFoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Erro ao selecionar foto.')));
      }
    }
  }

  @override
  Map<String, TextEditingController> get draftControllers => {
        '_nomeController': _nomeController,
        '_dosagemController': _dosagemController,
        '_alertaController': _alertaController,
        '_descricaoController': _descricaoController,
        '_fabricanteController': _fabricanteController,
        '_loteController': _loteController,
        '_quantidadeController': _quantidadeController,
      };

  @override
  Map<String, dynamic> get draftValues => {
        'frequenciaSelecionada': frequenciaSelecionada,
        '_alertas': _alertas,
        '_horarios': _horarios,
        'alertaSonoro': _alertaSonoro,
        'somAlerta': _somAlerta,
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
    if (v['alertaSonoro'] is bool) _alertaSonoro = v['alertaSonoro'] as bool;
    if (v['somAlerta'] is String) _somAlerta = v['somAlerta'] as String;
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
  final _descricaoController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _loteController = TextEditingController();
  final _quantidadeController = TextEditingController();
  bool _alertaSonoro = false;
  String _somAlerta = 'campainha';
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
      _descricaoController.text = med.descricao;
      _fabricanteController.text = med.fabricante;
      _loteController.text = med.lote;
      _quantidadeController.text = '${med.quantidade ?? ''}';
      _alertaSonoro = med.alertaSonoro;
      _somAlerta = med.somAlerta.isNotEmpty ? med.somAlerta : 'campainha';
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
    _descricaoController.dispose();
    _fabricanteController.dispose();
    _loteController.dispose();
    _quantidadeController.dispose();
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

    final quantidade = _quantidadeController.text.trim().isEmpty
        ? null : int.tryParse(_quantidadeController.text.trim());
    if (_quantidadeController.text.trim().isNotEmpty &&
        (quantidade == null || quantidade < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quantidade precisa ser um número inteiro não negativo.')));
      return;
    }
    final novoMedicamento = Medicamento(
      nome: _nomeController.text.trim(),
      dosagem: _dosagemController.text.trim(),
      frequencia: opcoesFrequencia[frequenciaSelecionada],
      horarios: List.from(_horarios),
      alertas: List.from(_alertas),
      descricao: _descricaoController.text.trim(),
      fabricante: _fabricanteController.text.trim(),
      lote: _loteController.text.trim(),
      quantidade: quantidade,
      alertaSonoro: _alertaSonoro,
      somAlerta: _alertaSonoro ? _somAlerta : '',
    );

    setState(() => _salvando = true);
    try {
      final salvo = widget.medicamento?.id == null
          ? await _apiService.criarMedicamento(novoMedicamento.toJson())
          : await _apiService.requisicao(
              'PATCH', '/medicamentos/${widget.medicamento!.id}',
              dados: novoMedicamento.toJson()) as Map<String, dynamic>;
      // The medication record is already persisted; report photo failures
      // separately so that a retry never creates a duplicate medication.
      String? avisoFoto;
      Map<String, dynamic> medicamentoComFoto = salvo;
      try {
        final id = salvo['id'];
        if (id != null && _fotoSelecionada != null && _fotoMime != null) {
          medicamentoComFoto = Map<String, dynamic>.from(await _apiService.requisicao(
            'PUT', '/medicamentos/$id/foto', dados: {
              'mime_type': _fotoMime,
              'foto_base64': base64Encode(_fotoSelecionada!),
            }) as Map);
        } else if (id != null && _removerFoto) {
          medicamentoComFoto = Map<String, dynamic>.from(await _apiService.requisicao(
            'DELETE', '/medicamentos/$id/foto') as Map);
        }
      } catch (_) {
        avisoFoto = 'Medicamento salvo, mas a foto não pôde ser atualizada.';
      }
      await clearDraft();
      if (mounted) {
        if (avisoFoto != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(avisoFoto)));
        }
        Navigator.pop(context, Medicamento.fromJson(medicamentoComFoto));
      }
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
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Foto do medicamento (opcional)'),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    OutlinedButton.icon(onPressed: () => _selecionarFoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria')),
                    OutlinedButton.icon(onPressed: () => _selecionarFoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined), label: const Text('Câmera')),
                    if (_fotoSelecionada != null || widget.medicamento?.fotoUrl != null)
                      TextButton.icon(onPressed: () => setState(() {
                        _fotoSelecionada = null; _fotoMime = null; _removerFoto = true;
                      }), icon: const Icon(Icons.delete_outline), label: const Text('Remover foto')),
                  ]),
                  if (_fotoSelecionada != null)
                    Image.memory(_fotoSelecionada!, height: 140, fit: BoxFit.contain),
                  if (widget.medicamento?.fotoUrl != null && _fotoSelecionada == null && !_removerFoto)
                    const Text('Há uma foto salva. Selecione outra para substituir.'),
                ]))),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              const Text('Informações complementares', style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _descricaoController, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descrição',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _fabricanteController,
                  decoration: const InputDecoration(labelText: 'Fabricante',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _loteController,
                  decoration: const InputDecoration(labelText: 'Lote',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade',
                      border: OutlineInputBorder())),
              SwitchListTile(title: const Text('Alerta sonoro'),
                  subtitle: const Text('Preferência salva no banco. Notificações do sistema ainda precisam ser configuradas.'),
                  value: _alertaSonoro,
                  onChanged: (valor) => setState(() => _alertaSonoro = valor)),
              if (_alertaSonoro) DropdownButtonFormField<String>(
                initialValue: ['campainha', 'sino', 'padrao'].contains(_somAlerta)
                    ? _somAlerta : 'campainha',
                decoration: const InputDecoration(labelText: 'Som preferido'),
                items: ['campainha', 'sino', 'padrao']
                    .map((som) => DropdownMenuItem(value: som, child: Text(som)))
                    .toList(),
                onChanged: (som) => setState(() => _somAlerta = som ?? 'campainha'),
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
