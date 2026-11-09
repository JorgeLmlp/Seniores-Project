import '../../services/draft_state.dart';
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

class _ComunicadosEnvioState extends State<ComunicadosEnvio>
    with DraftState<ComunicadosEnvio> {
  @override
  Map<String, TextEditingController> get draftControllers =>
      {'mensagemController': mensagemController};

  @override
  Map<String, dynamic> get draftValues =>
      {'selecionados': selecionados.map((d) => d.toJson()).toList()};

  @override
  void restoreDraftValues(Map<String, dynamic> v) {
    if (v['selecionados'] is List) {
      selecionados.clear();
      selecionados.addAll((v['selecionados'] as List)
          .map((d) => Destinatario.fromJson(Map<String, dynamic>.from(d))));
    }
  }

  late List<Destinatario> listaLocalEnvio;
  final List<Destinatario> selecionados = [];
  final TextEditingController mensagemController = TextEditingController();
  String? destinatarioSelecionadoValor;
  final ApiService _apiService = ApiService();
  bool _enviando = false;

  Future<void> _enviar() async {
    if (selecionados.isEmpty || mensagemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      await clearDraft();
      if (!mounted) return;
      Navigator.pop(context, {
        'destinatario': selecionados.first,
        'mensagem': mensagemController.text.trim(),
      });
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
      }
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
    saveDraftBeforeDispose();
    mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> nomesItens =
        listaLocalEnvio.map((e) => '${e.nome} (${e.vinculo})').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                          child: AppText(
                              texto: 'Comunicados',
                              estilo: AppText.titulo,
                              tamanho: 24)),
                    ],
                  )),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: Cores.azul, size: 26),
                    onPressed: () async {
                      final novoItem = await Navigator.push<Destinatario>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CadastroDestinatario()),
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
              SizedBox(height: 24),
              AppText(
                  texto: 'Destinatários',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              AppText(
                  texto: 'Escolha um ou mais',
                  estilo: AppText.corpo,
                  tamanho: 12,
                  cor: Cores.cinza),
              SizedBox(height: 8),
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
              SizedBox(height: 12),
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
              SizedBox(height: 24),
              AppText(
                  texto: 'Mensagem',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              SizedBox(height: 8),
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
              Spacer(),
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
