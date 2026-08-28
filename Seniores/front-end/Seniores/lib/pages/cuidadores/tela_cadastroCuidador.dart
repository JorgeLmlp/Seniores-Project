import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cuidador.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_botao.dart';
import '../../utils/cores.dart';
import '../../utils/mascaras.dart';
import '../../services/api_service.dart';

class CadastroCuidador extends StatefulWidget {
  const CadastroCuidador({super.key});

  @override
  State<CadastroCuidador> createState() => _TelaCadastroCuidadorState();
}

class _TelaCadastroCuidadorState extends State<CadastroCuidador> {
  final List<bool> diasSelecionados = [
    false,
    true,
    true,
    true,
    false,
    false,
    false
  ];

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController funcaoController = TextEditingController();
  final TextEditingController tel1Controller = TextEditingController();
  final TextEditingController tel2Controller = TextEditingController();
  final TextEditingController obsController = TextEditingController();
  final TextEditingController horaInicioController =
      TextEditingController(text: '08:00');
  final TextEditingController horaFimController =
      TextEditingController(text: '10:00');
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  @override
  void dispose() {
    nomeController.dispose();
    funcaoController.dispose();
    tel1Controller.dispose();
    tel2Controller.dispose();
    obsController.dispose();
    horaInicioController.dispose();
    horaFimController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (nomeController.text.trim().isEmpty ||
        funcaoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome e a função do cuidador.')),
      );
      return;
    }
    final cuidador = Cuidador(
      nome: nomeController.text.trim(),
      funcao: funcaoController.text.trim(),
      telefone1: tel1Controller.text,
      telefone2: tel2Controller.text,
      frequencia: List.from(diasSelecionados),
      horaInicio: horaInicioController.text,
      horaFim: horaFimController.text,
      observacoes: obsController.text,
    );
    setState(() => _salvando = true);
    try {
      await _apiService.criarRegistro('cuidadores', cuidador.toJson());
      if (mounted) Navigator.pop(context, cuidador);
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
    final diasSemana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Cores.preto, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const AppText(
                      texto: 'Novo Cuidador',
                      estilo: AppText.titulo,
                      tamanho: 24),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                              texto: 'Foto',
                              estilo: AppText.corpo,
                              peso: FontWeight.bold,
                              tamanho: 14,
                              cor: Cores.azul),
                          AppText(
                              texto: 'Escolha uma foto do cuidador',
                              estilo: AppText.corpo,
                              tamanho: 11,
                              cor: Cores.cinza),
                        ],
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Cores.azul,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const AppText(
                      texto: 'Nome',
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 13,
                      cor: Cores.azul),
                  const SizedBox(height: 6),
                  _buildTextField(
                      hint: 'Digite aqui...', controller: nomeController),
                  const SizedBox(height: 14),
                  const AppText(
                      texto: 'Função',
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 13,
                      cor: Cores.azul),
                  const SizedBox(height: 6),
                  _buildTextField(
                      hint: 'Digite aqui...', controller: funcaoController),
                  const SizedBox(height: 14),
                  const AppText(
                      texto: 'Número de telefone',
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 13,
                      cor: Cores.azul),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.phone,
                                color: Cores.azul, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildTextField(
                                hint: '(xx) xxxxx-xxxx',
                                controller: tel1Controller,
                                fontSize: 12,
                                inputFormatters: [TelefoneInputFormatter()],
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: Cores.azul, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildTextField(
                                hint: '(xx) xxxxx-xxxx',
                                controller: tel2Controller,
                                fontSize: 12,
                                inputFormatters: [TelefoneInputFormatter()],
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const AppText(
                      texto: 'Frequência',
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 13,
                      cor: Cores.azul),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final ativo = diasSelecionados[index];
                      return GestureDetector(
                        onTap: () => setState(() =>
                            diasSelecionados[index] = !diasSelecionados[index]),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ativo ? Cores.azul : Colors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                                color: ativo
                                    ? Cores.azul
                                    : Cores.cinza.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(
                              diasSemana[index],
                              style: TextStyle(
                                color: ativo ? Colors.white : Cores.azul,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  const AppText(
                      texto: 'Horário',
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 13,
                      cor: Cores.azul),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                          width: 90,
                          child: _buildTextField(
                              hint: '08:00',
                              controller: horaInicioController,
                              textAlign: TextAlign.center)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: AppText(
                            texto: 'ás',
                            estilo: AppText.corpo,
                            tamanho: 13,
                            cor: Cores.cinza),
                      ),
                      SizedBox(
                          width: 90,
                          child: _buildTextField(
                              hint: '10:00',
                              controller: horaFimController,
                              textAlign: TextAlign.center)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const AppText(
                      texto: 'Observações',
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 13,
                      cor: Cores.azul),
                  const SizedBox(height: 6),
                  TextField(
                    controller: obsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Digite aqui...',
                      hintStyle:
                          const TextStyle(color: Cores.cinza, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Cores.cinza.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Cores.azul),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Botao(
                    texto: 'Concluir',
                    fontSize: 14,
                    borderRadius: 12,
                    onPressed: _salvando ? () {} : _salvar,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    double fontSize = 13,
    TextAlign textAlign = TextAlign.start,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: fontSize, color: Cores.preto),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Cores.cinza, fontSize: fontSize),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Cores.cinza.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Cores.azul),
        ),
      ),
    );
  }
}
