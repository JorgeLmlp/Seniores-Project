import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../models/medicamento.dart';

class DetalhesMedicamento extends StatefulWidget {
  final Medicamento medicamento;

  const DetalhesMedicamento({super.key, required this.medicamento});

  @override
  State<DetalhesMedicamento> createState() => _DetalhesMedicamentoState();
}

class _DetalhesMedicamentoState extends State<DetalhesMedicamento> {
  // Lista de horários do dia gerada a partir do medicamento com o seu estado de conclusão
  late List<Map<String, dynamic>> _horariosHoje;

  @override
  void initState() {
    super.initState();
    // Inicializa os horários reais vindos do cadastro do remédio
    _horariosHoje = widget.medicamento.horarios.map((h) {
      return {'horario': h, 'status': 'pendente'}; // 'pendente', 'concluido'
    }).toList();
  }

  Color _obterCorStatus(String status) {
    switch (status) {
      case 'atrasado':
        return Cores.vermelho;
      case 'concluido':
        return Colors.green;
      default:
        return Cores.amarelo;
    }
  }

  void _alternarStatus(int index) {
    setState(() {
      String atual = _horariosHoje[index]['status'];
      if (atual == 'concluido') {
        _horariosHoje[index]['status'] = 'pendente';
      } else {
        _horariosHoje[index]['status'] = 'concluido';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicamento;
    final horariosFormatados = med.horarios.join(' - ');

    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com botão voltar e título
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 28,
                      color: Cores.preto,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const AppText(
                    texto: 'Medicamentos',
                    estilo: AppText.titulo,
                    tamanho: 24,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Card Principal com Informações do Banco
              CardPadrao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagem ilustrativa / Placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.medication, size: 64, color: Cores.azul),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome e botão de editar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText(
                            texto: med.nome,
                            tamanho: 22,
                            peso: FontWeight.bold,
                            cor: Cores.azul,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_square, color: Cores.azul),
                          onPressed: () {
                            // Ação para editar
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Detalhes textuais vindos da API
                    AppText(
                      texto: 'Horários:\n   ${horariosFormatados.isNotEmpty ? horariosFormatados : "Nenhum horário definido"}',
                      tamanho: 14,
                      cor: Colors.grey[700]!,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      texto: 'Frequência: ${med.frequencia}',
                      tamanho: 14,
                      cor: Colors.grey[700]!,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      texto: 'Dosagem: ${med.dosagem}',
                      tamanho: 14,
                      cor: Colors.grey[700]!,
                    ),
                    const SizedBox(height: 12),

                    // Exibição Dinâmica de Alertas cadastrados
                    if (med.alertas.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...med.alertas.map((alerta) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AppText(
                                    texto: alerta,
                                    tamanho: 13,
                                    cor: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 16),

                    // Seção "Hoje:"
                    const AppText(
                      texto: 'Hoje:',
                      tamanho: 16,
                      peso: FontWeight.bold,
                      cor: Cores.azul,
                    ),
                    const SizedBox(height: 10),

                    // Lista de horários do dia baseada no banco de dados
                    _horariosHoje.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Nenhum horário programado para hoje.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _horariosHoje.length,
                            separatorBuilder: (_, __) => const Divider(height: 16, color: Colors.black12),
                            itemBuilder: (context, index) {
                              final item = _horariosHoje[index];
                              final status = item['status'];
                              final cor = _obterCorStatus(status);

                              String textoBotao = 'Concluir';
                              if (status == 'concluido') textoBotao = 'Concluído';

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: cor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      AppText(
                                        texto: item['horario'],
                                        tamanho: 14,
                                        peso: FontWeight.bold,
                                        cor: Colors.black87,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () => _alternarStatus(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        textoBotao,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 1),
    );
  }
}