import 'package:flutter/material.dart';

import '../models/higiene.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class HigienePage extends StatefulWidget {
  const HigienePage({super.key});

  @override
  State<HigienePage> createState() => _HigienePageState();
}

class _HigienePageState extends State<HigienePage> {
  List<Higiene> _registros = [];
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
      final registros = await ApiService().listarHigienes(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _registros = registros;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar as rotinas de higiene.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirFormulario([Higiene? higiene]) async {
    final resultado = await showDialog<Higiene>(
      context: context,
      builder: (_) => FormularioHigiene(higiene: higiene),
    );
    if (resultado == null || !mounted) return;
    try {
      final salvo = resultado.id == null
          ? await ApiService().criarHigiene(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await ApiService().atualizarHigiene(resultado);
      if (!mounted) return;
      setState(() {
        final indice = _registros.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _registros = [salvo, ..._registros];
        } else {
          _registros[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar a rotina de higiene.');
    }
  }

  Future<void> _excluir(Higiene higiene) async {
    if (higiene.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir rotina?'),
        content: const Text('O checklist será removido do histórico.'),
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
      await ApiService().deletarHigiene(higiene.id!);
      if (mounted) {
        setState(() => _registros.removeWhere((item) => item.id == higiene.id));
      }
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível excluir a rotina de higiene.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist de higiene')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
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
            : _registros.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Nenhuma rotina de higiene registrada.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _registros.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final higiene = _registros[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        higiene.concluida
                            ? Icons.check_circle
                            : Icons.checklist,
                        color: higiene.concluida ? Colors.green : Colors.orange,
                      ),
                      title: Text(higiene.tipo),
                      subtitle: Text(
                        '${higiene.dataHora}\n'
                        '${higiene.itens.values.where((item) => item).length}/'
                        '${higiene.itens.length} itens concluídos',
                      ),
                      isThreeLine: true,
                      onTap: () => _abrirFormulario(higiene),
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _excluir(higiene),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FormularioHigiene extends StatefulWidget {
  final Higiene? higiene;

  const FormularioHigiene({super.key, this.higiene});

  @override
  State<FormularioHigiene> createState() => _FormularioHigieneState();
}

class _FormularioHigieneState extends State<FormularioHigiene> {
  static const _itensPadrao = [
    'Banho',
    'Higiene bucal',
    'Troca de roupa',
    'Higiene íntima',
    'Hidratação da pele',
  ];

  late final TextEditingController _tipo;
  late final TextEditingController _dataHora;
  late final TextEditingController _observacoes;
  late Map<String, bool> _itens;

  @override
  void initState() {
    super.initState();
    final higiene = widget.higiene;
    _tipo = TextEditingController(text: higiene?.tipo ?? 'Rotina diária');
    _dataHora = TextEditingController(
      text: higiene?.dataHora ?? _agoraFormatado(),
    );
    _observacoes = TextEditingController(text: higiene?.observacoes);
    _itens = higiene == null || higiene.itens.isEmpty
        ? {for (final item in _itensPadrao) item: false}
        : {...higiene.itens};
  }

  String _agoraFormatado() {
    final agora = DateTime.now();
    return '${agora.year.toString().padLeft(4, '0')}-'
        '${agora.month.toString().padLeft(2, '0')}-'
        '${agora.day.toString().padLeft(2, '0')} '
        '${agora.hour.toString().padLeft(2, '0')}:'
        '${agora.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tipo.dispose();
    _dataHora.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_tipo.text.trim().isEmpty ||
        _dataHora.text.trim().isEmpty ||
        !_itens.values.any((item) => item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe tipo, data/hora e conclua ao menos um item.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Higiene(
        id: widget.higiene?.id,
        tipo: _tipo.text.trim(),
        dataHora: _dataHora.text.trim(),
        itens: _itens,
        observacoes: _observacoes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.higiene == null ? 'Nova rotina' : 'Editar rotina'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampoTexto(hintText: 'Tipo de rotina', controller: _tipo),
              const SizedBox(height: 10),
              CampoTexto(hintText: 'Data e hora', controller: _dataHora),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Itens do checklist',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._itens.keys.map(
                (item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  value: _itens[item],
                  onChanged: (valor) => setState(() => _itens[item] = valor == true),
                ),
              ),
              CampoTexto(
                hintText: 'Observações',
                controller: _observacoes,
              ),
            ],
          ),
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
