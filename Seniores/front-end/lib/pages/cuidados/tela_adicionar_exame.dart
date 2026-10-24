import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import '../../models/exame.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/cores.dart';
import '../../utils/mascaras.dart';
import '../../services/api_service.dart';

class AdicionarExame extends StatefulWidget {
  const AdicionarExame({super.key});

  @override
  State<AdicionarExame> createState() => _AdicionarExameState();
}

class _AdicionarExameState extends State<AdicionarExame>
    with DraftState<AdicionarExame> {
  @override
  Map<String, TextEditingController> get draftControllers => {
        '_nomeExameController': _nomeExameController,
        '_localController': _localController,
        '_telefoneController': _telefoneController,
        '_whatsappController': _whatsappController,
        '_alertaController': _alertaController,
        '_cepController': _cepController,
        '_logradouroController': _logradouroController,
        '_bairroController': _bairroController,
        '_cidadeController': _cidadeController,
        '_estadoController': _estadoController
      };

  @override
  Map<String, dynamic> get draftValues => {
        '_statusSelecionado': _statusSelecionado,
        '_alertas': _alertas,
        'data': _dataSelecionada?.toIso8601String(),
        'hora': _horarioInicio.hour,
        'minuto': _horarioInicio.minute
      };

  @override
  void restoreDraftValues(Map<String, dynamic> v) {
    if (v['_statusSelecionado'] != null) {
      _statusSelecionado = v['_statusSelecionado'] as int;
    }
    if (v['_alertas'] is List) {
      _alertas.clear();
      _alertas.addAll((v['_alertas'] as List).cast<String>());
    }
    _dataSelecionada = DateTime.tryParse(v['data'] ?? '');
    if (v['hora'] is int) {
      _horarioInicio = TimeOfDay(hour: v['hora'], minute: v['minuto']);
    }
  }

  int _statusSelecionado = 0;
  DateTime? _dataSelecionada;
  TimeOfDay _horarioInicio = TimeOfDay(hour: 8, minute: 0);

  final TextEditingController _nomeExameController = TextEditingController();
  final TextEditingController _localController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _alertaController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  final List<String> _alertas = [];
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  final List<String> _estadosBrasileiros = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO'
  ];

  @override
  void dispose() {
    saveDraftBeforeDispose();
    _nomeExameController.dispose();
    _localController.dispose();
    _telefoneController.dispose();
    _whatsappController.dispose();
    _alertaController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (dataEscolhida != null) {
      setState(() {
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  Future<void> _selecionarHorario(BuildContext context) async {
    final TimeOfDay? horarioEscolhido = await showTimePicker(
      context: context,
      initialTime: _horarioInicio,
    );
    if (horarioEscolhido != null) {
      setState(() {
        _horarioInicio = horarioEscolhido;
      });
    }
  }

  void _mostrarSeletorEstado(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione o Estado',
              style: TextStyle(color: Cores.azul, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _estadosBrasileiros.length,
              itemBuilder: (context, index) {
                final uf = _estadosBrasileiros[index];
                return ListTile(
                  title:
                      Text(uf, style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() {
                      _estadoController.text = uf;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _salvarExame() async {
    if (_nomeExameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, informe o nome do exame.')),
      );
      return;
    }

    if (_dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione a data do exame.')),
      );
      return;
    }

    DateTime dataHoraCompleta = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horarioInicio.hour,
      _horarioInicio.minute,
    );

    Exame novoExame = Exame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nomeExame: _nomeExameController.text,
      local: _localController.text,
      dataHora: dataHoraCompleta,
      historico: _statusSelecionado == 1,
      concluido: _statusSelecionado == 1,
      telefone: _telefoneController.text,
      whatsapp: _whatsappController.text,
      cep: _cepController.text,
      logradouro: _logradouroController.text,
      bairro: _bairroController.text,
      cidade: _cidadeController.text,
      estado: _estadoController.text,
    );
    setState(() => _salvando = true);
    try {
      final salvo =
          await _apiService.criarRegistro('exames', novoExame.toJson());
      await clearDraft();
      if (!mounted) return;
      Navigator.pop(
        context,
        Exame(
          id: salvo['id'].toString(),
          nomeExame: novoExame.nomeExame,
          local: novoExame.local,
          dataHora: novoExame.dataHora,
          concluido: novoExame.concluido,
          historico: novoExame.historico,
          telefone: novoExame.telefone,
          whatsapp: novoExame.whatsapp,
          cep: novoExame.cep,
          logradouro: novoExame.logradouro,
          bairro: novoExame.bairro,
          cidade: novoExame.cidade,
          estado: novoExame.estado,
        ),
      );
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dataFormatada = 'Selecione a data';
    if (_dataSelecionada != null) {
      dataFormatada =
          '${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}';
    }

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
                      Icons.keyboard_double_arrow_left,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  AppText(
                    texto: 'Adicionar exame',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 24),
              AppText(
                  texto: 'Nome do exame',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              CampoTexto(
                hintText: 'Digite aqui...',
                controller: _nomeExameController,
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Nome do local',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              CampoTexto(
                hintText: 'Digite aqui...',
                controller: _localController,
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Status',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              GrupoBotoes(
                itens: ['Agendada', 'Finalizada', 'Cancelada'],
                selecionado: _statusSelecionado,
                onSelecionado: (index) =>
                    setState(() => _statusSelecionado = index),
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Data do exame',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selecionarData(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dataFormatada,
                        style: TextStyle(
                          color: _dataSelecionada == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Cores.azul, size: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Horário',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selecionarHorario(context),
                      child:
                          _buildTimeBox(texto: _horarioInicio.format(context)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              CampoTexto(
                hintText: 'CEP (00000-000)',
                controller: _cepController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.location_on_outlined),
                inputFormatters: [Cep()],
              ),
              SizedBox(height: 12),
              CampoTexto(
                hintText: 'Logradouro (Rua, Av...)',
                controller: _logradouroController,
                prefixIcon: Icon(Icons.home_outlined),
              ),
              SizedBox(height: 12),
              CampoTexto(
                hintText: 'Bairro',
                controller: _bairroController,
                prefixIcon: Icon(Icons.map_outlined),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CampoTexto(
                      hintText: 'Cidade',
                      controller: _cidadeController,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => _mostrarSeletorEstado(context),
                      child: AbsorbPointer(
                        child: CampoTexto(
                          hintText: 'UF',
                          controller: _estadoController,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Número de telefone',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              CampoTexto(
                hintText: '(xx) xxxxx-xxxx',
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(Icons.phone, color: Cores.azul, size: 22),
                inputFormatters: [TelefoneInputFormatter()],
              ),
              SizedBox(height: 10),
              CampoTexto(
                hintText: '(xx) xxxxx-xxxx',
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(Icons.chat, color: Cores.azul, size: 22),
                inputFormatters: [TelefoneInputFormatter()],
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Alertas',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CampoTexto(
                      hintText: 'Digite aqui...',
                      controller: _alertaController,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.black),
                      onPressed: () {
                        if (_alertaController.text.isNotEmpty) {
                          setState(() {
                            _alertas.add(_alertaController.text);
                            _alertaController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _alertas
                    .map((alerta) => Chip(
                          label: Text(alerta, style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 16),
              AppText(
                  texto: 'Pedido do exame',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              SizedBox(height: 4),
              Text('Escolha ou escaneie o pedido',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.upload_file, size: 18),
                    label: Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azul,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.qr_code_scanner, size: 18),
                    label: Text('Escanear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azul,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Center(
                child: Botao(
                  texto: "Concluir",
                  fontSize: 14,
                  altura: 45,
                  largura: 200,
                  backgroundColor: Cores.azul,
                  textColor: Colors.white,
                  borderRadius: 25,
                  onPressed: _salvando ? () {} : _salvarExame,
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 2),
    );
  }

  Widget _buildTimeBox({required String texto}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        texto,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
