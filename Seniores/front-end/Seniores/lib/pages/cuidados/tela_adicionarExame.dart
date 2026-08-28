import 'package:flutter/material.dart';
import '../../models/exame.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_textField.dart';
import '../../utils/cores.dart';
import '../../utils/mascaras.dart';
import '../../services/api_service.dart';

class AdicionarExame extends StatefulWidget {
  const AdicionarExame({super.key});

  @override
  State<AdicionarExame> createState() => _AdicionarExameState();
}

class _AdicionarExameState extends State<AdicionarExame> {
  int _statusSelecionado = 0;
  DateTime? _dataSelecionada;
  TimeOfDay _horarioInicio = const TimeOfDay(hour: 8, minute: 0);

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
          title: const Text('Selecione o Estado',
              style: TextStyle(color: Cores.azul, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _estadosBrasileiros.length,
              itemBuilder: (context, index) {
                final uf = _estadosBrasileiros[index];
                return ListTile(
                  title: Text(uf,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
        const SnackBar(content: Text('Por favor, informe o nome do exame.')),
      );
      return;
    }

    if (_dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a data do exame.')),
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
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
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
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.keyboard_double_arrow_left,
                      size: 28,
                      color: Cores.preto,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const AppText(
                    texto: 'Adicionar exame',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AppText(
                  texto: 'Nome do exame',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: 'Digite aqui...',
                controller: _nomeExameController,
              ),
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Nome do local',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: 'Digite aqui...',
                controller: _localController,
              ),
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Status',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              GrupoBotoes(
                itens: const ['Agendada', 'Finalizada', 'Cancelada'],
                selecionado: _statusSelecionado,
                onSelecionado: (index) =>
                    setState(() => _statusSelecionado = index),
              ),
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Data do exame',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selecionarData(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      const Icon(Icons.calendar_today,
                          color: Cores.azul, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Horário',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              CampoTexto(
                hintText: 'CEP (00000-000)',
                controller: _cepController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.location_on_outlined),
                inputFormatters: [Cep()],
              ),
              const SizedBox(height: 12),
              CampoTexto(
                hintText: 'Logradouro (Rua, Av...)',
                controller: _logradouroController,
                prefixIcon: const Icon(Icons.home_outlined),
              ),
              const SizedBox(height: 12),
              CampoTexto(
                hintText: 'Bairro',
                controller: _bairroController,
                prefixIcon: const Icon(Icons.map_outlined),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CampoTexto(
                      hintText: 'Cidade',
                      controller: _cidadeController,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Número de telefone',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: '(xx) xxxxx-xxxx',
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                prefixIcon:
                    const Icon(Icons.phone, color: Cores.azul, size: 22),
                inputFormatters: [TelefoneInputFormatter()],
              ),
              const SizedBox(height: 10),
              CampoTexto(
                hintText: '(xx) xxxxx-xxxx',
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.chat, color: Cores.azul, size: 22),
                inputFormatters: [TelefoneInputFormatter()],
              ),
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Alertas',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CampoTexto(
                      hintText: 'Digite aqui...',
                      controller: _alertaController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.black),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _alertas
                    .map((alerta) => Chip(
                          label: Text(alerta,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const AppText(
                  texto: 'Pedido do exame',
                  tamanho: 14,
                  peso: FontWeight.bold,
                  cor: Cores.azul),
              const SizedBox(height: 4),
              const Text('Escolha ou escaneie o pedido',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azul,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Escanear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azul,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }

  Widget _buildTimeBox({required String texto}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        texto,
        style: const TextStyle(
            color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
