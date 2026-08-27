import 'package:flutter/material.dart';
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

  final List<String> opcoesFrequencia = ["diário", "Semanal", "Mensal"];
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dosagemController = TextEditingController();
  final TextEditingController _alertaController = TextEditingController();
  final List<String> _horarios = ['8:00', '10:00'];
  final List<String> _alertas = [
    'Pode causar tontura',
    'tomar com água',
    'Tomar após alimentação',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _alertaController.dispose();
    super.dispose();
  }

  void _salvarMedicamento() {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite o nome do medicamento.')),
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

    Navigator.pop(context, novoMedicamento);
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
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF275DAD),
                      size: 36,
                    ),
                  ),
                ],
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
                    onTap: () {},
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