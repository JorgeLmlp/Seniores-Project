import 'package:flutter/material.dart';
import '../../models/exame.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../utils/cores.dart';

class DetalhesExame extends StatefulWidget {
  final Exame exame;

  const DetalhesExame({super.key, required this.exame});

  @override
  State<DetalhesExame> createState() => _DetalhesExameState();
}

class _DetalhesExameState extends State<DetalhesExame> {
  final TextEditingController _anotacaoController = TextEditingController();

  @override
  void dispose() {
    _anotacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String diaFormatado =
        '${widget.exame.dataHora.day.toString().padLeft(2, '0')}/${widget.exame.dataHora.month.toString().padLeft(2, '0')}';
    final String horaFormatada =
        '${widget.exame.dataHora.hour.toString().padLeft(2, '0')}:${widget.exame.dataHora.minute.toString().padLeft(2, '0')}';

    final String statusTexto =
        widget.exame.concluido ? 'Finalizado' : 'Agendado';

    // Montando o endereço completo unificando os campos
    final String enderecoCompleto = [
      if (widget.exame.logradouro != null &&
          widget.exame.logradouro!.isNotEmpty)
        widget.exame.logradouro,
      if (widget.exame.bairro != null && widget.exame.bairro!.isNotEmpty)
        'Bairro ${widget.exame.bairro}',
      if (widget.exame.cidade != null && widget.exame.cidade!.isNotEmpty)
        widget.exame.cidade,
      if (widget.exame.estado != null && widget.exame.estado!.isNotEmpty)
        widget.exame.estado,
      if (widget.exame.cep != null && widget.exame.cep!.isNotEmpty)
        'CEP ${widget.exame.cep}',
    ].join(', ');

    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com Botão de Voltar e Título
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
                    texto: 'Exame',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nome do Exame, Local e Ícone de Edição
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade400,
                    child: const Icon(Icons.local_hospital,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exame.nomeExame,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Cores.azul,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.exame.local.isNotEmpty
                              ? widget.exame.local
                              : 'Local não informado',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Cores.azul, size: 24),
                    onPressed: () {
                      // Ação para editar o exame se desejar
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data e Status
              Text(
                'Dia $diaFormatado, às $horaFormatada',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: $statusTexto',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Endereço Completo e Botão de Mapa
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

              // Telefones (Telefone Fixo e WhatsApp)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Cores.azul, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.exame.telefone.isNotEmpty
                                ? widget.exame.telefone
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
                            widget.exame.whatsapp.isNotEmpty
                                ? widget.exame.whatsapp
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

              // Anotações
              const AppText(
                texto: 'Anotações do exame',
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 1),
    );
  }
}
