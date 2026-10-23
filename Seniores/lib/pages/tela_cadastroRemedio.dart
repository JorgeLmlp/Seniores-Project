import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_textos.dart';
import '../widgets/custom_textField.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_menu.dart';
import '../models/medicamento.dart';

class CadastroRemedio extends StatefulWidget {
  const CadastroRemedio({super.key});

  @override
  State<CadastroRemedio> createState() => _CadastroRemedioState();
}

class _CadastroRemedioState extends State<CadastroRemedio> {
  int frequenciaSelecionada = 0;

  final List<String> opcoesFrequencia = ["diario", "semanal", "mensal"];
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dosagemController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _fabricanteController = TextEditingController();
  final TextEditingController _loteController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _alertaController = TextEditingController();
  final List<String> _horarios = [];
  final List<String> _alertas = [];
  bool _alertaSonoro = false;
  String _somAlerta = 'campainha';
  String? _fotoNome;
  List<int>? _fotoBytes;

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _descricaoController.dispose();
    _fabricanteController.dispose();
    _loteController.dispose();
    _quantidadeController.dispose();
    _alertaController.dispose();
    super.dispose();
  }

  void _salvarMedicamento() {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite o nome do medicamento.'),
        ),
      );
      return;
    }

    final novoMedicamento = Medicamento(
      nome: _nomeController.text.trim(),
      dosagem: _dosagemController.text.trim(),
      descricao: _descricaoController.text.trim(),
      fabricante: _fabricanteController.text.trim(),
      lote: _loteController.text.trim(),
      quantidade: int.tryParse(_quantidadeController.text.trim()),
      frequencia: opcoesFrequencia[frequenciaSelecionada],
      horarios: List.from(_horarios),
      alertas: List.from(_alertas),
      alertaSonoro: _alertaSonoro,
      somAlerta: _somAlerta,
      fotoNome: _fotoNome,
      fotoBytes: _fotoBytes,
    );

    Navigator.pop(context, novoMedicamento);
  }

  Future<void> _selecionarFoto() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (resultado == null || !mounted) return;
    final arquivo = resultado.files.single;
    if (arquivo.bytes == null || arquivo.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler a foto.')),
      );
      return;
    }
    setState(() {
      _fotoNome = arquivo.name;
      _fotoBytes = arquivo.bytes;
    });
  }

  Future<void> _adicionarHorario() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (horario == null || !mounted) return;
    final valor =
        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
    if (!_horarios.contains(valor)) {
      setState(() => _horarios.add(valor));
    }
  }

  Future<void> _capturarFoto() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (arquivo == null || !mounted) return;
    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) return;
    setState(() {
      _fotoNome = 'captura_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _fotoBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar: const Menu(paginaAtual: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
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
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const AppText(
                    texto: "Adicionar medicamento",
                    tamanho: 22,
                    peso: FontWeight.bold,
                    estilo: AppText.titulo,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppText(
                        texto: "Foto",
                        tamanho: 18,
                        peso: FontWeight.bold,
                        cor: Color(0xFF275DAD),
                        estilo: AppText.subtitulo,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        texto: "Escolha ou tire uma foto do medicamento",
                        tamanho: 12,
                        cor: Colors.black54,
                        estilo: AppText.corpo,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Selecionar imagem',
                        onPressed: _selecionarFoto,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF275DAD),
                          size: 30,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Capturar com câmera',
                        onPressed: _capturarFoto,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFF275DAD),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_fotoNome != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Foto selecionada: $_fotoNome'),
                ),

              const SizedBox(height: 20),

              const AppText(
                texto: "Nome do medicamento",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: "Digite aqui...",
                controller: _nomeController,
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: "Frequencia",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 8),
              GrupoBotoes(
                itens: opcoesFrequencia,
                selecionado: frequenciaSelecionada,
                onSelecionado: (index) {
                  setState(() {
                    frequenciaSelecionada = index;
                  });
                },
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: "Horarios",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: _adicionarHorario,
                    child: Container(
                      width: 45,
                      height: 38,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _horarios.map((horario) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            horario,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: "Dosagem",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: "Digite aqui...",
                controller: _dosagemController,
              ),

              const SizedBox(height: 20),
              const AppText(
                texto: "Descrição",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 8),
              CampoTexto(
                hintText: "Uso e observações...",
                controller: _descricaoController,
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CampoTexto(
                      hintText: "Fabricante",
                      controller: _fabricanteController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CampoTexto(
                      hintText: "Lote",
                      controller: _loteController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CampoTexto(
                hintText: "Quantidade disponível",
                controller: _quantidadeController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              const AppText(
                texto: "Alertas",
                tamanho: 18,
                peso: FontWeight.bold,
                cor: Color(0xFF275DAD),
                estilo: AppText.subtitulo,
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CampoTexto(
                    hintText: "Digite aqui...",
                    controller: _alertaController,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.grey),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _alertas.map((alerta) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alerta,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alerta sonoro'),
                value: _alertaSonoro,
                onChanged: (valor) => setState(() => _alertaSonoro = valor),
              ),
              if (_alertaSonoro)
                DropdownButtonFormField<String>(
                  initialValue: _somAlerta,
                  decoration: const InputDecoration(
                    labelText: 'Som do alerta',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'campainha',
                      child: Text('Campainha'),
                    ),
                    DropdownMenuItem(value: 'suave', child: Text('Suave')),
                    DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                  ],
                  onChanged: (valor) {
                    if (valor != null) setState(() => _somAlerta = valor);
                  },
                ),

              const SizedBox(height: 30),

              Center(
                child: Botao(
                  texto: "Concluir",
                  largura: 160,
                  altura: 45,
                  borderRadius: 12,
                  onPressed: _salvarMedicamento,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
