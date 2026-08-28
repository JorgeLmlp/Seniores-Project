import 'package:flutter/material.dart';
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
                    texto: 'Consulta',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade400,
                    child:
                        const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.consulta.nomeDoutor,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Cores.azul,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.consulta.especialidade.isNotEmpty
                              ? widget.consulta.especialidade
                              : 'Especialidade não informada',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Cores.azul, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Dia $diaFormatado, às $horaFormatada',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: $statusTexto',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Motivo: ${widget.consulta.motivo.isNotEmpty ? widget.consulta.motivo : "Não informado"}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (widget.consulta.alertas.isNotEmpty) ...[
                ...widget.consulta.alertas.map((alerta) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.amber, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                alerta,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      enderecoCompleto.isNotEmpty
                          ? enderecoCompleto
                          : 'Endereço não informado',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Cores.azul,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.location_on,
                          color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Cores.azul, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.consulta.telefone.isNotEmpty
                                ? widget.consulta.telefone
                                : 'Não informado',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.chat, color: Cores.azul, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.consulta.whatsapp.isNotEmpty
                                ? widget.consulta.whatsapp
                                : 'Não informado',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AppText(
                texto: 'Anotações da consulta',
                tamanho: 16,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _anotacaoController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Digite aqui...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppText(
                texto: 'Exames necessários',
                tamanho: 16,
                peso: FontWeight.bold,
                cor: Cores.azul,
              ),
              const SizedBox(height: 4),
              Text(
                'Clique para visualizar o exame',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.consulta.exames.map((exame) {
                  return Chip(
                    label: Text(exame),
                    labelStyle:
                        const TextStyle(fontSize: 12, color: Cores.verde),
                    avatar:
                        const Icon(Icons.check, size: 16, color: Cores.verde),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Cores.verde),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}
