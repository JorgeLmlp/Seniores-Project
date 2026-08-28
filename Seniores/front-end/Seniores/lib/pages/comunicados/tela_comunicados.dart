import 'package:flutter/material.dart';
import '../../widgets/custom_menu.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_botao.dart';
import '../../models/destinatario.dart';
import '../../utils/cores.dart';
import 'tela_cadastroDestinatario.dart';
import 'tela_envioComunicado.dart';
import 'tela_detalhesComunicado.dart';
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
        lista.addAll(resultados[0].map((registro) =>
            Destinatario.fromJson(registro['dados'] as Map<String, dynamic>)));
        for (final registro in resultados[1]) {
          final dados = registro['dados'] as Map<String, dynamic>;
          final destinatarios = dados['destinatarios'] as List<dynamic>? ?? [];
          if (destinatarios.isNotEmpty) {
            comunicadosEnviados.add({
              'destinatario': Destinatario.fromJson(
                  destinatarios.first as Map<String, dynamic>),
              'mensagem': dados['mensagem'] as String? ?? '',
            });
          }
        }
      });
    } on ApiException catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Cores.preto, size: 20),
                        onPressed: () => Navigator.canPop(context)
                            ? Navigator.pop(context)
                            : null,
                      ),
                      const AppText(
                          texto: 'Comunicados',
                          estilo: AppText.titulo,
                          tamanho: 24),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Cores.azul, size: 22),
                    onPressed: () async {
                      final novoItem = await Navigator.push<Destinatario>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroDestinatario()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  if (comunicadosEnviados.isNotEmpty) ...[
                    const AppText(
                        texto: 'Enviados Recentemente',
                        estilo: AppText.titulo,
                        tamanho: 18,
                        cor: Cores.azul),
                    const SizedBox(height: 8),
                    ...comunicadosEnviados.map((comunicado) {
                      Destinatario dest = comunicado['destinatario'];
                      String msg = comunicado['mensagem'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            padding: const EdgeInsets.all(16),
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
                                      const SizedBox(height: 4),
                                      AppText(
                                        texto: msg,
                                        estilo: AppText.corpo,
                                        tamanho: 13,
                                        cor: Cores.cinza,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 2),
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
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DetalhesComunicado(
                                                destinatario: dest,
                                                mensagem: msg,
                                              ),
                                            ),
                                          );
                                        },
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
                    const SizedBox(height: 24),
                    const AppText(
                        texto: 'Lista de Contatos',
                        estilo: AppText.titulo,
                        tamanho: 18,
                        cor: Cores.azul),
                    const SizedBox(height: 8),
                  ],
                  ...lista.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CardPadrao(
                        padding: const EdgeInsets.all(16),
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
                                const SizedBox(height: 2),
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
                                const SizedBox(height: 6),
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
                                    onPressed: () {},
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
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: Cores.azul,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ComunicadosEnvio(destinatariosIniciais: lista),
                      ),
                    );

                    if (resultado != null) {
                      setState(() {
                        comunicadosEnviados.add(resultado);
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 0),
    );
  }
}
