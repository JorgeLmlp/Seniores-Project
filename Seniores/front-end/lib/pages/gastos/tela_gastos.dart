import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models/gasto.dart';
import '../../services/api_service.dart';
import 'tela_novo_gasto.dart';

class Gastos extends StatefulWidget {
  const Gastos({super.key});
  @override
  State<Gastos> createState() => _GastosState();
}

class _GastosState extends State<Gastos> {
  List<Gasto> _registros = [];
  bool _carregando = true;
  String? _erro;
  String _periodo = 'mes';
  String _filtroTipo = 'todos';
  String _categoria = 'todas';
  String _grafico = 'barras';
  DateTime _referencia = DateTime.now();

  @override
  void initState() { super.initState(); _carregar(); }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final lista = await ApiService().listarRegistros('registros-financeiros');
      if (mounted) { setState(() => _registros = lista.map(Gasto.fromMap).toList()
        ..sort((a, b) => b.data.compareTo(a.data)));
      }
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Não foi possível carregar gastos.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Evita DropdownButton com value inexistente depois que a ultima despesa
  // de uma categoria e removida ou a lista e atualizada pela API.
  String get _categoriaAtiva => _categoria == 'todas' ||
      _registros.any((g) => g.categoria == _categoria)
      ? _categoria : 'todas';

  List<Gasto> get _filtrados => _registros.where((g) {
    if (_filtroTipo != 'todos' && g.tipo != _filtroTipo) return false;
    if (_categoriaAtiva != 'todas' && g.categoria != _categoriaAtiva) return false;
    if (_periodo == 'todos') return true;
    if (g.data.year != _referencia.year) return false;
    if (_periodo == 'mes' && g.data.month != _referencia.month) return false;
    return true;
  }).toList();

  Map<String, double> get _grupos {
    final valores = <String, double>{};
    for (final g in _filtrados.where((g) => g.tipo == 'despesa')) {
      valores[g.categoria] = (valores[g.categoria] ?? 0) + g.valor;
    }
    final ordenado = valores.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final agrupados = Map<String, double>.fromEntries(ordenado.take(5));
    if (ordenado.length > 5) agrupados['Outros'] = ordenado.skip(5).fold(0.0, (s,e) => s + e.value);
    return agrupados;
  }

  String _dinheiro(double n) => 'R\$ ${n.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _editar([Gasto? gasto]) async {
    final mudou = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => NovoGasto(gasto: gasto)));
    if (mudou == true && mounted) await _carregar();
  }

  Future<void> _excluir(Gasto gasto) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir lançamento?'), content: Text(gasto.categoria),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir'))],
    ));
    if (ok != true) return;
    try {
      await ApiService().excluirRegistro('registros-financeiros', gasto.id);
      if (mounted) await _carregar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Erro ao excluir.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final receita = _filtrados.where((g) => g.tipo == 'receita').fold(0.0, (double s,g) => s + g.valor);
    final despesa = _filtrados.where((g) => g.tipo == 'despesa').fold(0.0, (double s,g) => s + g.valor);
    final grupos = _grupos;
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos e receitas'), actions: [IconButton(onPressed: _carregar,
        icon: const Icon(Icons.refresh), tooltip: 'Atualizar')]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editar(),
        icon: const Icon(Icons.add), label: const Text('Lançamento')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820),
        child: RefreshIndicator(onRefresh: _carregar, child: ListView(
          padding: const EdgeInsets.all(16), children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              DropdownButton<String>(value: _periodo, items: const [
                DropdownMenuItem(value: 'mes', child: Text('Este mês')),
                DropdownMenuItem(value: 'ano', child: Text('Este ano')),
                DropdownMenuItem(value: 'todos', child: Text('Todo o histórico')),
              ], onChanged: (s) { if (s != null) setState(() => _periodo = s); }),
              DropdownButton<String>(value: _filtroTipo, items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos os tipos')),
                DropdownMenuItem(value: 'despesa', child: Text('Despesas')),
                DropdownMenuItem(value: 'receita', child: Text('Receitas')),
              ], onChanged: (s) { if (s != null) setState(() => _filtroTipo = s); }),
              DropdownButton<String>(value: _categoriaAtiva,
                items: [const DropdownMenuItem(value: 'todas', child: Text('Todas as categorias')),
                  ...(_registros.map((g) => g.categoria).where((c) => c.isNotEmpty).toSet().toList()..sort())
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                onChanged: (s) { if (s != null) setState(() => _categoria = s); }),
              if (_periodo != 'todos') IconButton(onPressed: () async {
                final data = await showDatePicker(context: context, initialDate: _referencia,
                  firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (data != null && mounted) setState(() => _referencia = data);
              }, icon: const Icon(Icons.calendar_month), tooltip: 'Selecionar período'),
            ]),
            if (_carregando) const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator())),
            if (_erro != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Text(_erro!), TextButton(onPressed: _carregar, child: const Text('Tentar novamente'))]))),
            if (!_carregando && _erro == null) ...[
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                _linha('Receitas', _dinheiro(receita)),
                _linha('Despesas', _dinheiro(despesa)),
                const Divider(),
                _linha('Saldo', _dinheiro(receita - despesa)),
              ]))),
              const SizedBox(height: 10),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Visualização de despesas', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(segments: const [
                    ButtonSegment(value: 'barras', label: Text('Barras')),
                    ButtonSegment(value: 'pizza', label: Text('Pizza')),
                    ButtonSegment(value: 'resumo', label: Text('Resumo')),
                  ], selected: {_grafico}, onSelectionChanged: (v) => setState(() => _grafico = v.first)),
                  const SizedBox(height: 16),
                  if (grupos.isEmpty) const Text('Sem despesas para o período selecionado.'),
                  if (grupos.isNotEmpty && _grafico == 'pizza')
                    SizedBox(height: 175, width: double.infinity, child: CustomPaint(
                      painter: _GraficoPizza(grupos.values.toList()))),
                  if (grupos.isNotEmpty && _grafico == 'barras')
                    ...grupos.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _linha(e.key, _dinheiro(e.value)),
                        LinearProgressIndicator(value: despesa == 0 ? 0 : e.value / despesa, minHeight: 9),
                      ]))),
                  if (grupos.isNotEmpty && _grafico == 'resumo') ...[
                    _linha('Categorias', '${grupos.length}'),
                    _linha('Lançamentos', '${_filtrados.where((g) => g.tipo == 'despesa').length}'),
                    _linha('Média por despesa', _dinheiro(despesa / math.max(1, _filtrados.where((g) => g.tipo == 'despesa').length))),
                  ],
                  if (_grafico == 'pizza') ...grupos.entries.map((e) => _linha(e.key, _dinheiro(e.value))),
                ],
              ))),
              const SizedBox(height: 10),
              Text('Lançamentos (${_filtrados.length})', style: Theme.of(context).textTheme.titleLarge),
              if (_filtrados.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Nenhum lançamento no período.')),
              ..._filtrados.map((g) => Card(child: ListTile(
                title: Text(g.categoria),
                subtitle: Text('${g.tipo == 'despesa' ? 'Despesa' : 'Receita'} • ${g.data.day}/${g.data.month}/${g.data.year}'),
                leading: Icon(g.tipo == 'despesa' ? Icons.trending_down : Icons.trending_up,
                  color: g.tipo == 'despesa' ? Colors.red : Colors.green),
                trailing: Text(_dinheiro(g.valor)),
                onTap: () => _editar(g),
                onLongPress: () => _excluir(g),
              ))),
              const SizedBox(height: 75),
            ],
          ],
        )),
      )),
    );
  }
  Widget _linha(String titulo, String valor) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Expanded(child: Text(titulo)), Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))]));
}

class _GraficoPizza extends CustomPainter {
  const _GraficoPizza(this.valores);
  final List<double> valores;
  static const paleta = [Color(0xFF275DAD), Color(0xFF29A878), Color(0xFFEFAB38),
    Color(0xFFF05C65), Color(0xFF9963C7), Color(0xFF4AB5C1)];
  @override
  void paint(Canvas canvas, Size size) {
    final total = valores.fold(0.0, (s,v) => s+v);
    if (total <= 0) return;
    final lado = math.min(size.width, size.height) - 10;
    final rect = Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: lado, height: lado);
    var angulo = -math.pi/2;
    for (var i=0;i<valores.length;i++) {
      final varredura = valores[i] / total * math.pi * 2;
      canvas.drawArc(rect, angulo, varredura, true, Paint()..color=paleta[i%paleta.length]);
      angulo += varredura;
    }
  }
  @override
  bool shouldRepaint(covariant _GraficoPizza old) => old.valores != valores;
}
