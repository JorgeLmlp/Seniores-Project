import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_botao.dart';
import '../../models/destinatario.dart';
import '../../utils/cores.dart';
import 'tela_cadastro_destinatario.dart';
import 'tela_envio_comunicado.dart';
import 'tela_detalhes_comunicado.dart';
import '../../services/api_service.dart';

class Destinatarios extends StatefulWidget {
  const Destinatarios({super.key});

  @override
  State<Destinatarios> createState() => _DestinatariosState();
}

class _DestinatariosState extends State<Destinatarios> {
  final List<Destinatario> lista = [];

  final List<Map<String, dynamic>> comunicadosEnviados = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final resultados = await Future.wait([
        _apiService.listarRegistros('destinatarios'),
        _apiService.listarRegistros('comunicados'),
      ]);
      if (!mounted) return;
      setState(() {
        lista.clear();
        comunicadosEnviados.clear();
        lista.addAll(resultados[0].map((registro) =>
            Destinatario.fromJson({
              ...(registro['dados'] as Map<String, dynamic>),
              'id': registro['id'],
            })));
        for (final registro in resultados[1]) {
          final dados = registro['dados'] as Map<String, dynamic>;
          final destinatarios = dados['destinatarios'] as List<dynamic>? ?? [];
          if (destinatarios.isNotEmpty) {
            comunicadosEnviados.add({
              'destinatario': Destinatario.fromJson(
                  destinatarios.first as Map<String, dynamic>),
              'mensagem': dados['mensagem'] as String? ?? '',
              'id': registro['id'],
              'status': dados['status'] as String? ?? 'pendente',
            });
          }
        }
      });
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
      }
    }
  }

  Future<void> _editarComunicado(Map<String, dynamic> item) async {
    final controller = TextEditingController(text: '${item['mensagem'] ?? ''}');
    try {
      final novoTexto = await showDialog<String>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Editar comunicado'),
          content: TextField(controller: controller, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mensagem')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Salvar')),
          ],
        ));
      if (novoTexto == null || novoTexto.isEmpty) return;
      await _apiService.atualizarRegistro('comunicados', item['id'],
          {'mensagem': novoTexto});
      if (mounted) await _carregar();
    } on ApiException catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _excluirDestinatario(Destinatario item) async {
    if (item.id == null) return;
    final confirmar = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir destinatário?'),
        content: Text('Remover ${item.nome} da lista de contatos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ));
    if (confirmar != true) return;
    try {
      await _apiService.excluirRegistro('destinatarios', item.id!);
      if (mounted) await _carregar();
    } on ApiException catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20),
                        onPressed: () => Navigator.canPop(context)
                            ? Navigator.pop(context)
                            : null,
                      ),
                      AppText(
                          texto: 'Comunicados',
                          estilo: AppText.titulo,
                          tamanho: 24),
                    ],
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.edit_outlined, color: Cores.azul, size: 22),
                    onPressed: () async {
                      final novoItem = await Navigator.push<Destinatario>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CadastroDestinatario()),
                      );

                      if (novoItem != null) {
                        setState(() {
                          lista.add(novoItem);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  if (comunicadosEnviados.isNotEmpty) ...[
                    AppText(
                        texto: 'Comunicados registrados',
                        estilo: AppText.titulo,
                        tamanho: 18,
                        cor: Cores.azul),
                    SizedBox(height: 8),
                    ...comunicadosEnviados.map((comunicado) {
                      Destinatario dest = comunicado['destinatario'];
                      String msg = comunicado['mensagem'];
                      final status = '${comunicado['status'] ?? 'pendente'}';

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalhesComunicado(
                                  destinatario: dest,
                                  mensagem: msg,
                                ),
                              ),
                            );
                          },
                          child: CardPadrao(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Lado esquerdo: Nome e Mensagem
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        texto: '${dest.nome} (${dest.vinculo})',
                                        estilo: AppText.corpo,
                                        peso: FontWeight.bold,
                                        tamanho: 16,
                                        cor: Cores.azul,
                                      ),
                                      SizedBox(height: 4),
                                      Text('Status: $status', style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      SizedBox(height: 4),
                                      AppText(
                                        texto: msg,
                                        estilo: AppText.corpo,
                                        tamanho: 13,
                                        cor: Cores.cinza,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (status == 'falhou' || status == 'pendente')
                                      IconButton(tooltip: 'Tentar enviar por e-mail',
                                        icon: const Icon(Icons.send_outlined),
                                        onPressed: () async {
                                          try {
                                            await _apiService.requisicao('POST',
                                                '/comunicados/${comunicado['id']}/enviar');
                                          } on ApiException catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.message)),
                                              );
                                            }
                                          }
                                          if (mounted) await _carregar();
                                        }),
                                    IconButton(tooltip: 'Excluir comunicado',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        final confirmar = await showDialog<bool>(context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Excluir comunicado?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancelar')),
                                              FilledButton(onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Excluir')),
                                            ],
                                          ));
                                        if (confirmar != true) return;
                                        try {
                                          await _apiService.excluirRegistro('comunicados', comunicado['id']);
                                          if (mounted) await _carregar();
                                        } on ApiException catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.message)),
                                            );
                                          }
                                        }
                                      }),
                                    SizedBox(height: 2),
                                    SizedBox(
                                      height: 28,
                                      width: 80,
                                      child: Botao(
                                        texto: 'Editar',
                                        fontSize: 11,
                                        borderRadius: 14,
                                        backgroundColor: Colors.white,
                                        textColor: Cores.azul,
                                        borderColor: Cores.azul,
                                        borderWidth: 1,
                                        onPressed: () => _editarComunicado(comunicado),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 24),
                    AppText(
                        texto: 'Lista de Contatos',
                        estilo: AppText.titulo,
                        tamanho: 18,
                        cor: Cores.azul),
                    SizedBox(height: 8),
                  ],
                  ...lista.map((item) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: CardPadrao(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                    texto: item.nome,
                                    estilo: AppText.corpo,
                                    peso: FontWeight.bold,
                                    tamanho: 16,
                                    cor: Cores.azul),
                                SizedBox(height: 2),
                                AppText(
                                    texto: item.vinculo,
                                    estilo: AppText.corpo,
                                    tamanho: 12,
                                    cor: Cores.cinza),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppText(
                                    texto: item.telefone,
                                    estilo: AppText.corpo,
                                    tamanho: 12,
                                    cor: Cores.cinza),
                                IconButton(tooltip: 'Excluir destinatário',
                                  onPressed: () => _excluirDestinatario(item),
                                  icon: const Icon(Icons.delete_outline)),
                                SizedBox(height: 6),
                                SizedBox(
                                  height: 28,
                                  width: 80,
                                  child: Botao(
                                    texto: 'Editar',
                                    fontSize: 11,
                                    borderRadius: 14,
                                    backgroundColor: Colors.white,
                                    textColor: Cores.azul,
                                    borderColor: Cores.azul,
                                    borderWidth: 1,
                                    onPressed: () async {
                                      await Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => CadastroDestinatario(destinatario: item)));
                                      if (mounted) await _carregar();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: Cores.azul,
                  child: Icon(Icons.add, color: Colors.white),
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ComunicadosEnvio(destinatariosIniciais: lista),
                      ),
                    );

                    if (resultado != null && mounted) await _carregar();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Menu(paginaAtual: 0),
    );
  }
}
