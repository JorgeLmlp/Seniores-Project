import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_botao.dart';
import '../../widgets/custom_textField.dart';
import '../../utils/cores.dart';
import '../../models/destinatario.dart';
import 'tela_cadastroDestinatario.dart';
import '../../services/api_service.dart';

class ComunicadosEnvio extends StatefulWidget {
  final List<Destinatario> destinatariosIniciais;

  const ComunicadosEnvio({super.key, required this.destinatariosIniciais});

  @override
  State<ComunicadosEnvio> createState() => _ComunicadosEnvioState();
}

class _ComunicadosEnvioState extends State<ComunicadosEnvio> {
  late List<Destinatario> listaLocalEnvio;
  final List<Destinatario> selecionados = [];
  final TextEditingController mensagemController = TextEditingController();
  String? destinatarioSelecionadoValor;
  final ApiService _apiService = ApiService();
  bool _enviando = false;

  Future<void> _enviar() async {
    if (selecionados.isEmpty || mensagemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Selecione ao menos um destinatário e digite uma mensagem.')),
      );
      return;
    }
    final dadosApi = {
      'destinatarios': selecionados.map((item) => item.toJson()).toList(),
      'mensagem': mensagemController.text.trim(),
    };
    setState(() => _enviando = true);
    try {
      await _apiService.criarRegistro('comunicados', dadosApi);
      if (!mounted) return;
      Navigator.pop(context, {
        'destinatario': selecionados.first,
        'mensagem': mensagemController.text.trim(),
      });
    } on ApiException catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    listaLocalEnvio = List.from(widget.destinatariosIniciais);
  }

  @override
  void dispose() {
    mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> nomesItens =
        listaLocalEnvio.map((e) => '${e.nome} (${e.vinculo})').toList();

    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Cores.preto, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const AppText(
                          texto: 'Comunicados',
                          estilo: AppText.titulo,
                          tamanho: 24),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Cores.azul, size: 26),
                    onPressed: () async {
                      final novoItem = await Navigator.push<Destinatario>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroDestinatario()),
                      );

                      if (novoItem != null) {
                        setState(() {
                          listaLocalEnvio.add(novoItem);
                          destinatarioSelecionadoValor =
                              '${novoItem.nome} (${novoItem.vinculo})';
                          if (!selecionados.contains(novoItem)) {
                            selecionados.add(novoItem);
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AppText(
                  texto: 'Destinatários',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              const AppText(
                  texto: 'Escolha um ou mais',
                  estilo: AppText.corpo,
                  tamanho: 12,
                  cor: Cores.cinza),
              const SizedBox(height: 8),
              CampoDropdown(
                hintText: 'Selecione',
                valor: destinatarioSelecionadoValor,
                itens: nomesItens,
                onChanged: (String? novoValor) {
                  if (novoValor != null) {
                    setState(() {
                      destinatarioSelecionadoValor = novoValor;
                      final itemEncontrado = listaLocalEnvio.firstWhere(
                        (e) => '${e.nome} (${e.vinculo})' == novoValor,
                      );
                      if (!selecionados.contains(itemEncontrado)) {
                        selecionados.add(itemEncontrado);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selecionados.map((item) {
                  return Chip(
                    label: Text('${item.nome} (${item.vinculo})'),
                    onDeleted: () {
                      setState(() {
                        selecionados.remove(item);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const AppText(
                  texto: 'Mensagem',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: TextField(
                  controller: mensagemController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Botao(
                  texto: 'Enviar',
                  backgroundColor: Cores.azul,
                  textColor: Colors.white,
                  onPressed: _enviando ? () {} : _enviar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
