import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../models/medicamento.dart';
import '../../services/api_service.dart';
import 'tela_cadastroRemedio.dart';

class DetalhesMedicamento extends StatefulWidget {
  final Medicamento medicamento;

  const DetalhesMedicamento({super.key, required this.medicamento});

  @override
  State<DetalhesMedicamento> createState() => _DetalhesMedicamentoState();
}

class _DetalhesMedicamentoState extends State<DetalhesMedicamento> {
  late Medicamento _med;
  bool _ocupado = true;
  String get _dia => DateTime.now().toIso8601String().substring(0, 10);
  // Lista de horários do dia gerada a partir do medicamento com o seu estado de conclusão
  late List<Map<String, dynamic>> _horariosHoje;

  @override
  void initState() {
    super.initState();
    _med = widget.medicamento;
    // Inicializa os horários reais vindos do cadastro do remédio
    _horariosHoje = widget.medicamento.horarios.map((h) {
      return {'horario': h, 'status': 'pendente'}; // 'pendente', 'concluido'
    }).toList();
    _carregarStatus();
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

  Future<void> _carregarStatus() async {
    try {
      final dados = await ApiService()
              .requisicao('GET', '/medicamentos/${_med.id}/doses/$_dia')
          as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _horariosHoje = _med.horarios
            .map((h) => <String, dynamic>{
                  'horario': h,
                  'status': dados[h] == true ? 'concluido' : 'pendente'
                })
            .toList();
        _ocupado = false;
      });
    } catch (e) {
      _erro(e);
    }
  }

  void _erro(Object e) {
    if (!mounted) return;
    setState(() => _ocupado = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException
            ? e.message
            : 'Não foi possível salvar o medicamento.')));
  }

  Future<void> _alternarStatus(int index) async {
    setState(() => _ocupado = true);
    try {
      await ApiService()
          .requisicao('PUT', '/medicamentos/${_med.id}/doses/$_dia', dados: {
        'horario': _horariosHoje[index]['horario'],
        'concluida': _horariosHoje[index]['status'] != 'concluido'
      });
      await _carregarStatus();
    } catch (e) {
      _erro(e);
    }
  }

  Future<void> _editar() async {
    final med = await Navigator.push<Medicamento>(context,
        MaterialPageRoute(builder: (_) => CadastroRemedio(medicamento: _med)));
    if (med == null || !mounted) return;
    setState(() {
      _med = med;
      _ocupado = true;
    });
    await _carregarStatus();
  }

  @override
  Widget build(BuildContext context) {
    final med = _med;
    final horariosFormatados = med.horarios.join(' - ');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com botão voltar e título
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
                    texto: 'Medicamentos',
                    estilo: AppText.titulo,
                    tamanho: 24,
                  )),
                ],
              ),
              SizedBox(height: 20),

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
                        child:
                            Icon(Icons.medication, size: 64, color: Cores.azul),
                      ),
                    ),
                    SizedBox(height: 16),

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
                          icon: Icon(Icons.edit_square, color: Cores.azul),
                          onPressed: _ocupado ? null : _editar,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Detalhes textuais vindos da API
                    AppText(
                      texto:
                          'Horários:\n   ${horariosFormatados.isNotEmpty ? horariosFormatados : "Nenhum horário definido"}',
                      tamanho: 14,
                      cor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 4),
                    AppText(
                      texto: 'Frequência: ${med.frequencia}',
                      tamanho: 14,
                      cor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 4),
                    AppText(
                      texto: 'Dosagem: ${med.dosagem}',
                      tamanho: 14,
                      cor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 12),

                    // Exibição Dinâmica de Alertas cadastrados
                    if (med.alertas.isNotEmpty) ...[
                      SizedBox(height: 4),
                      ...med.alertas.map((alerta) => Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.amber, size: 20),
                                SizedBox(width: 8),
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
                    SizedBox(height: 16),

                    // Seção "Hoje:"
                    AppText(
                      texto: 'Hoje:',
                      tamanho: 16,
                      peso: FontWeight.bold,
                      cor: Cores.azul,
                    ),
                    SizedBox(height: 10),

                    // Lista de horários do dia baseada no banco de dados
                    _horariosHoje.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Nenhum horário programado para hoje.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _horariosHoje.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 16, color: Colors.black12),
                            itemBuilder: (context, index) {
                              final item = _horariosHoje[index];
                              final status = item['status'];
                              final cor = _obterCorStatus(status);

                              String textoBotao = 'Concluir';
                              if (status == 'concluido') {
                                textoBotao = 'Concluído';
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      SizedBox(width: 12),
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
                                      onPressed: _ocupado
                                          ? null
                                          : () => _alternarStatus(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        textoBotao,
                                        style: TextStyle(
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
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 1),
    );
  }
}
