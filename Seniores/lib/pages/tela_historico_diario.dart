import 'package:flutter/material.dart';

import '../models/registroDiario.dart';
import 'tela_registroDiario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_menu.dart';

class HistoricoDiario extends StatefulWidget {
  const HistoricoDiario({super.key});

  @override
  State<HistoricoDiario> createState() => _HistoricoDiarioState();
}

class _HistoricoDiarioState extends State<HistoricoDiario> {
  List<RegistroModel> _registros = [];
  bool _carregando = true;
  String _periodo = 'Todos';
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
      final registros = await ApiService().listarRegistrosDiarios(
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
      _mostrarErro('Não foi possível carregar o histórico do diário.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  List<RegistroModel> get _filtrados {
    final limite = switch (_periodo) {
      '7 dias' => DateTime.now().subtract(const Duration(days: 7)),
      '30 dias' => DateTime.now().subtract(const Duration(days: 30)),
      '90 dias' => DateTime.now().subtract(const Duration(days: 90)),
      _ => null,
    };
    return _registros.where((registro) {
      return limite == null ||
          (registro.data != null && !registro.data!.isBefore(limite));
    }).toList();
  }

  Future<void> _novoRegistro() async {
    final salvo = await Navigator.push<RegistroModel>(
      context,
      MaterialPageRoute(builder: (_) => const RegistroDiario()),
    );
    if (salvo != null && mounted) {
      setState(() => _registros = [salvo, ..._registros]);
    }
  }

  Future<void> _editar(RegistroModel registro) async {
    if (registro.id == null) return;
    final editado = await showDialog<RegistroModel>(
      context: context,
      builder: (_) => _DialogoEdicaoDiario(registro: registro),
    );
    if (editado == null || !mounted) return;
    try {
      final salvo = await ApiService().atualizarRegistroDiario(editado);
      if (!mounted) return;
      setState(() {
        _registros = _registros
            .map((item) => item.id == salvo.id ? salvo : item)
            .toList();
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível atualizar o registro.');
    }
  }

  Future<void> _excluir(RegistroModel registro) async {
    if (registro.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text('O registro diário será removido.'),
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
      await ApiService().deletarRegistroDiario(registro.id!);
      if (!mounted) return;
      setState(() => _registros.removeWhere((item) => item.id == registro.id));
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível excluir o registro.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final registros = _filtrados;
    return Scaffold(
      appBar: AppBar(title: const Text('Diário de saúde')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _periodo,
              decoration: const InputDecoration(
                labelText: 'Filtrar período',
                border: OutlineInputBorder(),
              ),
              items: const ['Todos', '7 dias', '30 dias', '90 dias']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _periodo = value);
              },
            ),
            const SizedBox(height: 16),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (_erro != null)
              Column(
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            else if (registros.isEmpty)
              const Text('Nenhum registro encontrado para o período.')
            else
              ...registros.map(
                (registro) => Card(
                  child: ListTile(
                    title: Text(_dataTexto(registro.data)),
                    subtitle: Text(
                      'Humor ${registro.humor.toStringAsFixed(1)} • '
                      'Dor ${registro.dor.toStringAsFixed(1)} • '
                      '${registro.totalIncidentes} incidente(s)',
                    ),
                    onTap: () => _editar(registro),
                    trailing: IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _excluir(registro),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoRegistro,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const Menu(paginaAtual: 3),
    );
  }

  String _dataTexto(DateTime? data) {
    if (data == null) return 'Sem data';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

class _DialogoEdicaoDiario extends StatefulWidget {
  final RegistroModel registro;

  const _DialogoEdicaoDiario({required this.registro});

  @override
  State<_DialogoEdicaoDiario> createState() => _DialogoEdicaoDiarioState();
}

class _DialogoEdicaoDiarioState extends State<_DialogoEdicaoDiario> {
  late final TextEditingController _humor;
  late final TextEditingController _dor;
  late final TextEditingController _apetite;
  late final TextEditingController _mobilidade;
  late final TextEditingController _observacoes;
  late final TextEditingController _duvidas;

  @override
  void initState() {
    super.initState();
    final registro = widget.registro;
    _humor = TextEditingController(text: registro.humor.toString());
    _dor = TextEditingController(text: registro.dor.toString());
    _apetite = TextEditingController(text: registro.apetite.toString());
    _mobilidade = TextEditingController(text: registro.mobilidade.toString());
    _observacoes = TextEditingController(text: registro.observacoes);
    _duvidas = TextEditingController(text: registro.duvidas);
  }

  @override
  void dispose() {
    _humor.dispose();
    _dor.dispose();
    _apetite.dispose();
    _mobilidade.dispose();
    _observacoes.dispose();
    _duvidas.dispose();
    super.dispose();
  }

  void _salvar() {
    final valores = [
      _humor,
      _dor,
      _apetite,
      _mobilidade,
    ].map((item) => double.tryParse(item.text.replaceAll(',', '.'))).toList();
    if (valores.any((item) => item == null || item < 0 || item > 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As notas devem estar entre 0 e 10.')),
      );
      return;
    }
    Navigator.pop(
      context,
      RegistroModel(
        id: widget.registro.id,
        data: widget.registro.data,
        humor: valores[0]!,
        dor: valores[1]!,
        apetite: valores[2]!,
        mobilidade: valores[3]!,
        totalIncidentes: widget.registro.totalIncidentes,
        tendencia: widget.registro.tendencia,
        observacoes: _observacoes.text.trim(),
        duvidas: _duvidas.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar registro diário'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final campo in [
              ('Humor', _humor),
              ('Dor', _dor),
              ('Apetite', _apetite),
              ('Mobilidade', _mobilidade),
            ]) ...[
              TextField(
                controller: campo.$2,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: campo.$1),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _observacoes,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            TextField(
              controller: _duvidas,
              decoration: const InputDecoration(labelText: 'Dúvidas'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
