import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/consulta.dart';
import '../models/exames.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_menu.dart';
import '../widgets/custom_textField.dart';
import 'tela_documentos_exame.dart';

enum AgendaTipo { consulta, exame }

class ConsultasExames extends StatelessWidget {
  const ConsultasExames({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Consultas e exames'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Consultas'),
              Tab(text: 'Exames'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AgendaTab(tipo: AgendaTipo.consulta),
            AgendaTab(tipo: AgendaTipo.exame),
          ],
        ),
        bottomNavigationBar: const Menu(paginaAtual: 2),
      ),
    );
  }
}

class AgendaTab extends StatefulWidget {
  final AgendaTipo tipo;

  const AgendaTab({super.key, required this.tipo});

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  final _api = ApiService();
  List<Consulta> _consultas = [];
  List<Exame> _exames = [];
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  bool get _ehConsulta => widget.tipo == AgendaTipo.consulta;

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
      if (_ehConsulta) {
        _consultas = await _api.listarConsultas(
          SessionService.instance.pacienteId,
        );
      } else {
        _exames = await _api.listarExames(SessionService.instance.pacienteId);
      }
      if (mounted) setState(() => _carregando = false);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = exception.message;
        });
      }
    } on StateError catch (exception) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = exception.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Não foi possível carregar os dados. Tente novamente.';
        });
      }
    }
  }

  Future<void> _abrirFormulario([Object? item]) async {
    final resultado = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioAgenda(tipo: widget.tipo, item: item),
      ),
    );
    if (resultado == null || !mounted) return;

    setState(() => _salvando = true);
    try {
      if (resultado is Consulta) {
        final salvo = resultado.id == null
            ? await _api.criarConsulta(
                SessionService.instance.pacienteId,
                resultado,
              )
            : await _api.atualizarConsulta(resultado);
        final indice = _consultas.indexWhere((item) => item.id == salvo.id);
        setState(() {
          if (indice >= 0) {
            _consultas[indice] = salvo;
          } else {
            _consultas = [..._consultas, salvo];
          }
        });
      } else if (resultado is Exame) {
        final salvo = resultado.id == null
            ? await _api.criarExame(
                SessionService.instance.pacienteId,
                resultado,
              )
            : await _api.atualizarExame(resultado);
        final indice = _exames.indexWhere((item) => item.id == salvo.id);
        setState(() {
          if (indice >= 0) {
            _exames[indice] = salvo;
          } else {
            _exames = [..._exames, salvo];
          }
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar os dados.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir(Object item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_ehConsulta ? 'Excluir consulta?' : 'Excluir exame?'),
        content: const Text('Esta ação não pode ser desfeita.'),
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
      if (item is Consulta && item.id != null) {
        await _api.deletarConsulta(item.id!);
        setState(
          () => _consultas.removeWhere((consulta) => consulta.id == item.id),
        );
      } else if (item is Exame && item.id != null) {
        await _api.deletarExame(item.id!);
        setState(() => _exames.removeWhere((exame) => exame.id == item.id));
      }
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir os dados.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vazio = _ehConsulta ? _consultas.isEmpty : _exames.isEmpty;
    return Stack(
      children: [
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else if (_erro != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_erro!, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _carregar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        else if (vazio)
          Center(
            child: Text(
              _ehConsulta
                  ? 'Nenhuma consulta cadastrada.'
                  : 'Nenhum exame cadastrado.',
            ),
          )
        else if (_ehConsulta)
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _consultas.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _cardConsulta(_consultas[index]),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _exames.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _cardExame(_exames[index]),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _salvando ? null : () => _abrirFormulario(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _cardConsulta(Consulta consulta) {
    return Card(
      child: ListTile(
        title: Text(consulta.titulo),
        subtitle: Text(
          [
            '${consulta.data}${consulta.hora.isEmpty ? '' : ' às ${consulta.hora}'}',
            if (consulta.especialidade.isNotEmpty) consulta.especialidade,
            if (consulta.profissional.isNotEmpty) consulta.profissional,
            if (consulta.local.isNotEmpty) consulta.local,
          ].join('\n'),
        ),
        onTap: () => _abrirFormulario(consulta),
        trailing: PopupMenuButton<String>(
          onSelected: (acao) {
            switch (acao) {
              case 'mapa':
                _abrirMapa(consulta.local);
              case 'telefone':
                _abrirTelefone(consulta.telefone);
              case 'whatsapp':
                _abrirWhatsApp(consulta.telefone);
              case 'excluir':
                _excluir(consulta);
            }
          },
          itemBuilder: (_) => [
            if (consulta.local.isNotEmpty)
              const PopupMenuItem(value: 'mapa', child: Text('Abrir no mapa')),
            if (consulta.telefone.isNotEmpty) ...[
              const PopupMenuItem(value: 'telefone', child: Text('Ligar')),
              const PopupMenuItem(
                value: 'whatsapp',
                child: Text('Abrir WhatsApp'),
              ),
            ],
            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Widget _cardExame(Exame exame) {
    return Card(
      child: ListTile(
        title: Text(exame.nome),
        subtitle: Text(
          [
            exame.data,
            if (exame.laboratorio.isNotEmpty) exame.laboratorio,
            if (exame.local.isNotEmpty) exame.local,
          ].join('\n'),
        ),
        onTap: () => _abrirFormulario(exame),
        trailing: PopupMenuButton<String>(
          onSelected: (acao) {
            if (acao == 'mapa') _abrirMapa(exame.local);
            if (acao == 'documentos') _abrirDocumentos(exame);
            if (acao == 'excluir') _excluir(exame);
          },
          itemBuilder: (_) => [
            if (exame.local.isNotEmpty)
              const PopupMenuItem(value: 'mapa', child: Text('Abrir no mapa')),
            const PopupMenuItem(value: 'documentos', child: Text('Documentos')),
            const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirMapa(String local) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': local,
    });
    await _abrirUri(uri, 'Não foi possível abrir o mapa.');
  }

  Future<void> _abrirDocumentos(Exame exame) async {
    if (exame.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentosExame(exame: exame)),
    );
  }

  Future<void> _abrirTelefone(String telefone) async {
    await _abrirUri(
      Uri(scheme: 'tel', path: telefone),
      'Não foi possível abrir o telefone.',
    );
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    final numeros = telefone.replaceAll(RegExp(r'\D'), '');
    final comPais = numeros.startsWith('55') ? numeros : '55$numeros';
    await _abrirUri(
      Uri.https('wa.me', '/$comPais'),
      'Não foi possível abrir o WhatsApp.',
    );
  }

  Future<void> _abrirUri(Uri uri, String erro) async {
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }
}

class FormularioAgenda extends StatefulWidget {
  final AgendaTipo tipo;
  final Object? item;

  const FormularioAgenda({super.key, required this.tipo, this.item});

  @override
  State<FormularioAgenda> createState() => _FormularioAgendaState();
}

class _FormularioAgendaState extends State<FormularioAgenda> {
  late final TextEditingController _nomeController;
  late final TextEditingController _especialidadeController;
  late final TextEditingController _profissionalController;
  late final TextEditingController _dataController;
  late final TextEditingController _horaController;
  late final TextEditingController _localController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _observacoesController;

  bool get _ehConsulta => widget.tipo == AgendaTipo.consulta;

  @override
  void initState() {
    super.initState();
    final consulta = widget.item is Consulta ? widget.item as Consulta : null;
    final exame = widget.item is Exame ? widget.item as Exame : null;
    _nomeController = TextEditingController(
      text: consulta?.titulo ?? exame?.nome ?? '',
    );
    _especialidadeController = TextEditingController(
      text: consulta?.especialidade ?? '',
    );
    _profissionalController = TextEditingController(
      text: consulta?.profissional ?? '',
    );
    _dataController = TextEditingController(
      text: consulta?.data ?? exame?.data ?? '',
    );
    _horaController = TextEditingController(text: consulta?.hora ?? '');
    _localController = TextEditingController(
      text: consulta?.local ?? exame?.local ?? '',
    );
    _telefoneController = TextEditingController(text: consulta?.telefone ?? '');
    _observacoesController = TextEditingController(
      text: consulta?.observacoes ?? exame?.observacoes ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _especialidadeController.dispose();
    _profissionalController.dispose();
    _dataController.dispose();
    _horaController.dispose();
    _localController.dispose();
    _telefoneController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_nomeController.text.trim().isEmpty ||
        _dataController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome/título e data são obrigatórios.')),
      );
      return;
    }
    if (_ehConsulta) {
      final anterior = widget.item is Consulta ? widget.item as Consulta : null;
      Navigator.pop(
        context,
        Consulta(
          id: anterior?.id,
          titulo: _nomeController.text.trim(),
          especialidade: _especialidadeController.text.trim(),
          profissional: _profissionalController.text.trim(),
          data: _dataController.text.trim(),
          hora: _horaController.text.trim(),
          local: _localController.text.trim(),
          telefone: _telefoneController.text.trim(),
          observacoes: _observacoesController.text.trim(),
        ),
      );
    } else {
      final anterior = widget.item is Exame ? widget.item as Exame : null;
      Navigator.pop(
        context,
        Exame(
          id: anterior?.id,
          nome: _nomeController.text.trim(),
          data: _dataController.text.trim(),
          laboratorio: _especialidadeController.text.trim(),
          local: _localController.text.trim(),
          observacoes: _observacoesController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ehConsulta ? 'Consulta' : 'Exame')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CampoTexto(
            hintText: _ehConsulta ? 'Título da consulta' : 'Nome do exame',
            controller: _nomeController,
          ),
          const SizedBox(height: 12),
          CampoTexto(
            hintText: 'Data (AAAA-MM-DD)',
            controller: _dataController,
            keyboardType: TextInputType.datetime,
          ),
          if (_ehConsulta) ...[
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Horário',
              controller: _horaController,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Especialidade',
              controller: _especialidadeController,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Profissional',
              controller: _profissionalController,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Telefone',
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
            ),
          ] else ...[
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Laboratório',
              controller: _especialidadeController,
            ),
          ],
          const SizedBox(height: 12),
          CampoTexto(hintText: 'Local', controller: _localController),
          const SizedBox(height: 12),
          CampoTexto(
            hintText: 'Observações',
            controller: _observacoesController,
          ),
          const SizedBox(height: 24),
          Botao(texto: 'Salvar', altura: 48, onPressed: _salvar),
        ],
      ),
    );
  }
}
