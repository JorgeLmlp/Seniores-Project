import 'package:flutter/material.dart';

import '../../models/gasto.dart';
import '../../services/api_service.dart';

class NovoGasto extends StatefulWidget {
  const NovoGasto({super.key, this.gasto});
  final Gasto? gasto;
  @override
  State<NovoGasto> createState() => _NovoGastoState();
}

class _NovoGastoState extends State<NovoGasto> {
  final _chave = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  String _tipo = 'despesa';
  DateTime _data = DateTime.now();
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    if (g != null) {
      _descricao.text = g.categoria;
      _valor.text = g.valor.toStringAsFixed(2).replaceAll('.', ',');
      _tipo = g.tipo;
      _data = g.data;
    }
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  double? _numero(String s) {
    var valor = s.trim().replaceAll(RegExp(r'[^0-9,.]'), '');
    if (valor.contains(',')) valor = valor.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(valor);
  }

  Future<void> _salvar() async {
    if (!_chave.currentState!.validate()) return;
    setState(() { _salvando = true; _erro = null; });
    final dados = {
      'descricao': _descricao.text.trim(),
      'valor': _numero(_valor.text),
      'tipo': _tipo,
      'data': _data.toIso8601String(),
    };
    try {
      if (widget.gasto == null) {
        await ApiService().criarRegistro('registros-financeiros', dados);
      } else {
        await ApiService().atualizarRegistro('registros-financeiros', widget.gasto!.id, dados);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Erro ao salvar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.gasto == null ? 'Novo lançamento' : 'Editar lançamento')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 580),
      child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _chave,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(controller: _descricao, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
            validator: (s) => (s ?? '').trim().isEmpty ? 'Informe a descrição' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _valor, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor (R\$)', border: OutlineInputBorder()),
            validator: (s) => (_numero(s ?? '') ?? 0) <= 0 ? 'Informe um valor maior que zero' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
              DropdownMenuItem(value: 'receita', child: Text('Receita'))],
            onChanged: (v) { if (v != null) setState(() => _tipo = v); }),
          const SizedBox(height: 16),
          ListTile(title: const Text('Data do lançamento'), subtitle: Text('${_data.day.toString().padLeft(2,'0')}/${_data.month.toString().padLeft(2,'0')}/${_data.year}'),
            trailing: const Icon(Icons.calendar_month), onTap: () async {
              final data = await showDatePicker(context: context, initialDate: _data,
                firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (data != null && mounted) setState(() => _data = data);
            }),
          if (_erro != null) Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 20),
          FilledButton(onPressed: _salvando ? null : _salvar,
            child: Text(_salvando ? 'Salvando...' : 'Salvar lançamento')),
        ]))))),
  );
}
