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
      if (widget.exame.logradouro.isNotEmpty) widget.exame.logradouro,
      if (widget.exame.bairro.isNotEmpty) 'Bairro ${widget.exame.bairro}',
      if (widget.exame.cidade.isNotEmpty) widget.exame.cidade,
      if (widget.exame.estado.isNotEmpty) widget.exame.estado,
      if (widget.exame.cep.isNotEmpty) 'CEP ${widget.exame.cep}',
    ].join(', ');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com Botão de Voltar e Título
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
                    texto: 'Exame',
                    estilo: AppText.titulo,
                    tamanho: 22,
                    peso: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Nome do Exame, Local e Ícone de Edição
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade400,
                    child: Icon(Icons.local_hospital,
                        size: 36, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exame.nomeExame,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Cores.azul,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.exame.local.isNotEmpty
                              ? widget.exame.local
                              : 'Local não informado',
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
                    onPressed: () {
                      // Ação para editar o exame se desejar
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Data e Status
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
              SizedBox(height: 16),

              // Endereço Completo e Botão de Mapa
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
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Telefones (Telefone Fixo e WhatsApp)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: Cores.azul, size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.exame.telefone.isNotEmpty
                                ? widget.exame.telefone
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
                        Icon(Icons.chat, color: Cores.azul, size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.exame.whatsapp.isNotEmpty
                                ? widget.exame.whatsapp
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

              // Anotações
              AppText(
                texto: 'Anotações do exame',
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
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 1),
    );
  }
}
