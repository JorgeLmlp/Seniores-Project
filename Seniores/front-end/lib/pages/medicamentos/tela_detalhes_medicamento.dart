import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';
import '../../models/medicamento.dart';
import '../../services/api_service.dart';
import 'tela_cadastro_remedio.dart';

class DetalhesMedicamento extends StatefulWidget {
  final Medicamento medicamento;

  const DetalhesMedicamento({super.key, required this.medicamento});

  @override
  State<DetalhesMedicamento> createState() => _DetalhesMedicamentoState();
}

class _DetalhesMedicamentoState extends State<DetalhesMedicamento> {
  late Medicamento _med;
  Timer? _relogio;
  Uint8List? _foto;
  String _ultimoDia = DateTime.now().toIso8601String().substring(0,10);
  bool _ocupado = true;
  Map<String, String>? _ultimaConclusao;
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
    _carregarFoto();
    _relogio = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final hoje = _dia;
      if (hoje != _ultimoDia) {
        _ultimoDia = hoje;
        _carregarStatus();
      } else {
        setState(() {}); // Recalcula atrasado / proximo / programado.
      }
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _carregarFoto() async {
    if (_med.fotoUrl == null) {
      if (mounted) setState(() => _foto = null);
      return;
    }
    try {
      final bytes = await ApiService().baixarArquivo(_med.fotoUrl!);
      if (mounted) setState(() => _foto = bytes);
    } catch (_) { /* Picture is optional and must not block medication details. */ }
  }

  String _statusReal(Map<String, dynamic> item) {
    if (item['status'] == 'concluido') return 'concluido';
    final partes = '${item['horario']}'.split(':');
    if (partes.length != 2) return 'programado';
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null || h > 23 || m > 59) return 'programado';
    final agora = DateTime.now();
    final horario = DateTime(agora.year, agora.month, agora.day, h, m);
    final minutos = horario.difference(agora).inMinutes;
    if (horario.isBefore(agora)) return 'atrasado';
    return minutos <= 30 ? 'proximo' : 'programado';
  }

  Color _obterCorStatus(String status) {
    switch (status) {
      case 'atrasado': return Cores.vermelho;
      case 'concluido': return Colors.green;
      case 'proximo': return Cores.amarelo;
      default: return Cores.azul;
    }
  }

  Future<void> _excluir() async {
    if (_med.id == null) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir medicamento?'),
      content: Text('Remover ${_med.nome} do cadastro? Essa ação não pode ser desfeita.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
      ],
    ));
    if (ok != true) return;
    setState(() => _ocupado = true);
    try {
      await ApiService().excluirRegistro('medicamentos', _med.id!);
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      _erro(erro);
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
    final horario = _horariosHoje[index]['horario'].toString();
    final concluindo = _horariosHoje[index]['status'] != 'concluido';
    String observacao = '';
    if (concluindo) {
      // Captura a observação pelo onChanged para não descartar um
      // TextEditingController enquanto a janela ainda está fechando.
      final resposta = await showDialog<String>(context: context,
        builder: (ctx) => AlertDialog(title: const Text('Confirmar dose'),
          content: TextField(maxLines: 3,
            onChanged: (texto) => observacao = texto,
            decoration: const InputDecoration(labelText: 'Observação (opcional)')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, observacao), child: const Text('Confirmar'))]));
      if (resposta == null || !mounted) return;
      observacao = resposta;
    }
    setState(() => _ocupado = true);
    try {
      await ApiService()
          .requisicao('PUT', '/medicamentos/${_med.id}/doses/$_dia', dados: {
        'horario': horario,
        'concluida': concluindo,
        if (concluindo) 'observacao': observacao,
      });
      await _carregarStatus();
      if (!mounted) return;
      setState(() {
        if (concluindo) {
          _ultimaConclusao = {'nome': _med.nome, 'horario': horario};
        } else if (_ultimaConclusao?['horario'] == horario) {
          _ultimaConclusao = null;
        }
      });
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
    await _carregarFoto();
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
                    onPressed: () => Navigator.pop(context, _ultimaConclusao),
                  ),
                  SizedBox(width: 8),
                  AppText(
                    texto: 'Medicamentos',
                    estilo: AppText.titulo,
                    tamanho: 24,
                  ),
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
                        child: _foto == null
                            ? Icon(Icons.medication, size: 64, color: Cores.azul)
                            : Image.memory(_foto!, fit: BoxFit.contain,
                                semanticLabel: 'Foto do medicamento'),
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
                              final status = _statusReal(item);
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
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _ocupado ? null : _excluir,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir medicamento'),
                style: OutlinedButton.styleFrom(foregroundColor: Cores.vermelho),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 1),
    );
  }
}
