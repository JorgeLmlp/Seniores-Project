import 'package:flutter/material.dart';
import '../../services/acoes_externas.dart';
import '../../services/api_service.dart';
import 'editar_agendamento.dart';
import '../../models/consulta.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';

class DetalhesConsulta extends StatefulWidget {
  final Consulta consulta;

  const DetalhesConsulta({super.key, required this.consulta});

  @override
  State<DetalhesConsulta> createState() => _DetalhesConsultaState();
}

class _DetalhesConsultaState extends State<DetalhesConsulta> {
  final TextEditingController _anotacaoController = TextEditingController();

  @override
  void dispose() {
    _anotacaoController.dispose();
    super.dispose();
  }

  Future<void> _editar() async {
    final mudou = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => EditarAgendamento(recurso: 'consultas',
        id: widget.consulta.id, dados: widget.consulta.toJson()),
    ));
    if (mudou == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir consulta?'),
      content: const Text('Este registro será removido do aplicativo.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('Excluir'))],
    ));
    if (ok != true) return;
    try {
      await ApiService().excluirRegistro('consultas', widget.consulta.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Erro ao excluir.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String diaFormatado =
        '${widget.consulta.dataHora.day.toString().padLeft(2, '0')}/${widget.consulta.dataHora.month.toString().padLeft(2, '0')}';
    final String horaFormatada =
        '${widget.consulta.dataHora.hour.toString().padLeft(2, '0')}:${widget.consulta.dataHora.minute.toString().padLeft(2, '0')}';

    final String statusTexto =
        widget.consulta.historico ? 'Finalizada' : 'Agendada';

    final String enderecoCompleto = [
      if (widget.consulta.logradouro.isNotEmpty) widget.consulta.logradouro,
      if (widget.consulta.bairro.isNotEmpty) 'Bairro ${widget.consulta.bairro}',
      if (widget.consulta.cidade.isNotEmpty) widget.consulta.cidade,
      if (widget.consulta.estado.isNotEmpty) widget.consulta.estado,
      if (widget.consulta.cep.isNotEmpty) 'CEP ${widget.consulta.cep}',
    ].join(', ');

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
                      Icons.arrow_back_ios_new,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  AppText(
                    texto: 'Consulta',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade400,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.consulta.nomeDoutor,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Cores.azul,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.consulta.especialidade.isNotEmpty
                              ? widget.consulta.especialidade
                              : 'Especialidade não informada',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.edit_outlined, color: Cores.azul, size: 24),
                    onPressed: _editar,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Dia $diaFormatado, às $horaFormatada',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 4),
              Text(
                'Status: $statusTexto',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 4),
              Text(
                'Motivo: ${widget.consulta.motivo.isNotEmpty ? widget.consulta.motivo : "Não informado"}',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 12),
              if (widget.consulta.alertas.isNotEmpty) ...[
                ...widget.consulta.alertas.map((alerta) => Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.amber, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                alerta,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      enderecoCompleto.isNotEmpty
                          ? enderecoCompleto
                          : 'Endereço não informado',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Cores.azul,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.location_on,
                          color: Colors.white, size: 20),
                      onPressed: enderecoCompleto.isEmpty ? null : () => AcoesExternas.mapa(context, enderecoCompleto),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(tooltip: "Ligar", icon: Icon(Icons.phone, color: Cores.azul, size: 18), onPressed: widget.consulta.telefone.isEmpty ? null : () => AcoesExternas.telefone(context, widget.consulta.telefone)),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.consulta.telefone.isNotEmpty
                                ? widget.consulta.telefone
                                : 'Não informado',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(tooltip: "Abrir WhatsApp", icon: Icon(Icons.chat, color: Cores.azul, size: 18), onPressed: widget.consulta.whatsapp.isEmpty ? null : () => AcoesExternas.whatsapp(context, widget.consulta.whatsapp)),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.consulta.whatsapp.isNotEmpty
                                ? widget.consulta.whatsapp
                                : 'Não informado',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              AppText(
                texto: 'Anotações da consulta',
                tamanho: 16,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _anotacaoController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Digite aqui...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              AppText(
                texto: 'Exames necessários',
                tamanho: 16,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              SizedBox(height: 4),
              Text(
                'Clique para visualizar o exame',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.consulta.exames.map((exame) {
                  return Chip(
                    label: Text(exame),
                    labelStyle: TextStyle(fontSize: 12, color: Cores.verde),
                    avatar: Icon(Icons.check, size: 16, color: Cores.verde),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Cores.verde),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(onPressed: _excluir,
                icon: const Icon(Icons.delete_outline), label: const Text('Excluir registro')),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 2),
    );
  }
}
