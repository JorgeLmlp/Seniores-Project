import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/alerta_emergencia.dart';
import '../models/contato_emergencia.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Seguranca extends StatefulWidget {
  const Seguranca({super.key});

  @override
  State<Seguranca> createState() => _SegurancaState();
}

class _SegurancaState extends State<Seguranca> {
  List<ContatoEmergencia> _contatos = [];
  List<AlertaEmergencia> _alertas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await Future.wait([
        ApiService().listarContatosEmergencia(
          SessionService.instance.pacienteId,
        ),
        ApiService().listarAlertasEmergencia(
          SessionService.instance.pacienteId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _contatos = dados[0] as List<ContatoEmergencia>;
        _alertas = dados[1] as List<AlertaEmergencia>;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar os dados de emergência.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirContato([ContatoEmergencia? contato]) async {
    final resultado = await showDialog<ContatoEmergencia>(
      context: context,
      builder: (_) => FormularioContatoEmergencia(contato: contato),
    );
    if (resultado == null || !mounted) return;
    try {
      final salvo = resultado.id == null
          ? await ApiService().criarContatoEmergencia(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await ApiService().atualizarContatoEmergencia(resultado);
      if (!mounted) return;
      setState(() {
        final indice = _contatos.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _contatos = [..._contatos, salvo];
        } else {
          _contatos[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar o contato.');
    }
  }

  Future<void> _excluirContato(ContatoEmergencia contato) async {
    if (contato.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir contato?'),
        content: Text(
          '${contato.nome} será removido dos contatos de emergência.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await ApiService().deletarContatoEmergencia(contato.id!);
      if (!mounted) return;
      setState(() => _contatos.removeWhere((item) => item.id == contato.id));
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível excluir o contato.');
    }
  }

  Future<void> _emitirAlerta() async {
    if (_contatos.isEmpty) {
      _mostrarMensagem('Cadastre ao menos um contato de emergência primeiro.');
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativar alerta de emergência?'),
        content: const Text(
          'O alerta será registrado para os contatos cadastrados. Confirme para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final alerta = await showDialog<AlertaEmergencia>(
      context: context,
      builder: (_) => const FormularioAlertaEmergencia(),
    );
    if (alerta == null || !mounted) return;
    try {
      final salvo = await ApiService().criarAlertaEmergencia(
        SessionService.instance.pacienteId,
        alerta,
      );
      if (!mounted) return;
      setState(() => _alertas = [salvo, ..._alertas]);
      _mostrarMensagem('Alerta registrado.');
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível emitir o alerta.');
    }
  }

  Future<void> _resolver(AlertaEmergencia alerta) async {
    if (alerta.id == null) return;
    try {
      final resolvido = await ApiService().resolverAlertaEmergencia(alerta.id!);
      if (!mounted) return;
      setState(() {
        _alertas = _alertas
            .map((item) => item.id == resolvido.id ? resolvido : item)
            .toList();
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível resolver o alerta.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _abrirContatoExterno(
    ContatoEmergencia contato,
    String acao,
  ) async {
    final numeros = contato.telefone.replaceAll(RegExp(r'\D'), '');
    final comPais = numeros.startsWith('55') ? numeros : '55$numeros';
    final uri = switch (acao) {
      'ligar' => Uri(scheme: 'tel', path: contato.telefone),
      'whatsapp' => Uri.https('wa.me', '/$comPais'),
      'sms' => Uri(
        scheme: 'sms',
        path: contato.telefone,
        queryParameters: {
          'body': 'Alerta de emergência do aplicativo Seniores.',
        },
      ),
      _ => null,
    };
    if (uri == null) return;
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu) {
      _mostrarMensagem('Não foi possível abrir o aplicativo escolhido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segurança e emergência')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 280),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _erro != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Botão de pânico',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use somente em uma situação de emergência.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Botao(
                            texto: 'Ativar alerta',
                            backgroundColor: Colors.red.shade700,
                            altura: 48,
                            onPressed: _emitirAlerta,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Contatos de emergência',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Adicionar contato',
                        onPressed: () => _abrirContato(),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  if (_contatos.isEmpty)
                    const Text('Nenhum contato cadastrado.')
                  else
                    ..._contatos.map(
                      (contato) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.contact_phone_outlined),
                          title: Text(contato.nome),
                          subtitle: Text(
                            '${contato.telefone}'
                            '${contato.parentesco.isEmpty ? '' : '\n${contato.parentesco}'}',
                          ),
                          onTap: () => _abrirContato(contato),
                          trailing: PopupMenuButton<String>(
                            onSelected: (acao) {
                              if (acao == 'excluir') _excluirContato(contato);
                              if (acao != 'excluir') {
                                _abrirContatoExterno(contato, acao);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'ligar',
                                child: Text('Ligar'),
                              ),
                              PopupMenuItem(
                                value: 'whatsapp',
                                child: Text('Abrir WhatsApp'),
                              ),
                              PopupMenuItem(
                                value: 'sms',
                                child: Text('Enviar SMS'),
                              ),
                              PopupMenuItem(
                                value: 'excluir',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Histórico de alertas',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_alertas.isEmpty)
                    const Text('Nenhum alerta emitido.')
                  else
                    ..._alertas.map(
                      (alerta) => Card(
                        child: ListTile(
                          leading: Icon(
                            alerta.status == 'resolvido'
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: alerta.status == 'resolvido'
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(alerta.status),
                          subtitle: Text(
                            '${alerta.dataHora?.toLocal() ?? ''}'
                            '${alerta.localizacao.isEmpty ? '' : '\n${alerta.localizacao}'}'
                            '${alerta.observacoes.isEmpty ? '' : '\n${alerta.observacoes}'}',
                          ),
                          trailing: alerta.status == 'resolvido'
                              ? null
                              : TextButton(
                                  onPressed: () => _resolver(alerta),
                                  child: const Text('Resolver'),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class FormularioContatoEmergencia extends StatefulWidget {
  final ContatoEmergencia? contato;

  const FormularioContatoEmergencia({super.key, this.contato});

  @override
  State<FormularioContatoEmergencia> createState() =>
      _FormularioContatoEmergenciaState();
}

class _FormularioContatoEmergenciaState
    extends State<FormularioContatoEmergencia> {
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _parentesco;
  late final TextEditingController _observacoes;

  @override
  void initState() {
    super.initState();
    final contato = widget.contato;
    _nome = TextEditingController(text: contato?.nome);
    _telefone = TextEditingController(text: contato?.telefone);
    _parentesco = TextEditingController(text: contato?.parentesco);
    _observacoes = TextEditingController(text: contato?.observacoes);
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _parentesco.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_nome.text.trim().isEmpty || _telefone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e telefone são obrigatórios.')),
      );
      return;
    }
    Navigator.pop(
      context,
      ContatoEmergencia(
        id: widget.contato?.id,
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim(),
        parentesco: _parentesco.text.trim(),
        observacoes: _observacoes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contato == null ? 'Novo contato' : 'Editar contato'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(hintText: 'Nome', controller: _nome),
            const SizedBox(height: 10),
            CampoTexto(
              hintText: 'Telefone',
              controller: _telefone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Parentesco', controller: _parentesco),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Observações', controller: _observacoes),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        Botao(
          texto: 'Salvar',
          largura: 100,
          altura: 42,
          fontSize: 14,
          onPressed: _salvar,
        ),
      ],
    );
  }
}

class FormularioAlertaEmergencia extends StatefulWidget {
  const FormularioAlertaEmergencia({super.key});

  @override
  State<FormularioAlertaEmergencia> createState() =>
      _FormularioAlertaEmergenciaState();
}

class _FormularioAlertaEmergenciaState
    extends State<FormularioAlertaEmergencia> {
  final _localizacao = TextEditingController();
  final _observacoes = TextEditingController();

  @override
  void dispose() {
    _localizacao.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes do alerta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(
              hintText: 'Localização (opcional)',
              controller: _localizacao,
            ),
            const SizedBox(height: 10),
            CampoTexto(
              hintText: 'Observações (opcional)',
              controller: _observacoes,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        Botao(
          texto: 'Emitir alerta',
          largura: 125,
          altura: 42,
          fontSize: 13,
          backgroundColor: Colors.red,
          onPressed: () => Navigator.pop(
            context,
            AlertaEmergencia(
              localizacao: _localizacao.text.trim(),
              observacoes: _observacoes.text.trim(),
            ),
          ),
        ),
      ],
    );
  }
}
