import 'package:flutter/material.dart';

import '../models/gasto.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Gastos extends StatefulWidget {
  const Gastos({super.key});

  @override
  State<Gastos> createState() => _GastosState();
}

class _GastosState extends State<Gastos> {
  List<Gasto> _gastos = [];
  bool _carregando = true;
  String _periodo = 'Todos';
  String _categoria = 'Todos';
  String _tipo = 'Todos';
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
      final gastos = await ApiService().listarGastos(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _gastos = gastos;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar os gastos.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  List<Gasto> get _filtrados {
    final limite = switch (_periodo) {
      '7 dias' => DateTime.now().subtract(const Duration(days: 7)),
      '30 dias' => DateTime.now().subtract(const Duration(days: 30)),
      '90 dias' => DateTime.now().subtract(const Duration(days: 90)),
      _ => null,
    };
    return _gastos.where((gasto) {
      final data = DateTime.tryParse(gasto.data);
      return (limite == null || (data != null && !data.isBefore(limite))) &&
          (_categoria == 'Todos' || gasto.categoria == _categoria) &&
          (_tipo == 'Todos' || gasto.tipo == _tipo);
    }).toList();
  }

  Future<void> _abrirFormulario([Gasto? gasto]) async {
    final resultado = await showDialog<Gasto>(
      context: context,
      builder: (_) => FormularioGasto(gasto: gasto),
    );
    if (resultado == null || !mounted) return;
    try {
      final salvo = resultado.id == null
          ? await ApiService().criarGasto(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await ApiService().atualizarGasto(resultado);
      if (!mounted) return;
      setState(() {
        final indice = _gastos.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _gastos = [salvo, ..._gastos];
        } else {
          _gastos[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar o gasto.');
    }
  }

  Future<void> _excluir(Gasto gasto) async {
    if (gasto.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir gasto?'),
        content: Text('${gasto.descricao} será removido.'),
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
      await ApiService().deletarGasto(gasto.id!);
      if (!mounted) return;
      setState(() => _gastos.removeWhere((item) => item.id == gasto.id));
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível excluir o gasto.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<String> _opcoes(String Function(Gasto) obter) {
    final valores =
        _gastos.map(obter).where((item) => item.isNotEmpty).toSet().toList()
          ..sort();
    return ['Todos', ...valores];
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final total = filtrados.fold<double>(
      0,
      (soma, gasto) => soma + gasto.valor,
    );
    final categorias = _opcoes((gasto) => gasto.categoria);
    final tipos = _opcoes((gasto) => gasto.tipo);
    if (!categorias.contains(_categoria)) _categoria = 'Todos';
    if (!tipos.contains(_tipo)) _tipo = 'Todos';
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _periodo,
              decoration: const InputDecoration(
                labelText: 'Período',
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
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: categorias
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _categoria = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de gasto',
                border: OutlineInputBorder(),
              ),
              items: tipos
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _tipo = value);
              },
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFEAF1FF),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total filtrado: R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _graficoCategorias(filtrados),
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
            else if (filtrados.isEmpty)
              const Text('Nenhum gasto encontrado para os filtros.')
            else
              ...filtrados.map(
                (gasto) => Card(
                  child: ListTile(
                    title: Text(gasto.descricao),
                    subtitle: Text(
                      '${gasto.data}'
                      '${gasto.categoria.isEmpty ? '' : '\n${gasto.categoria}'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('R\$ ${gasto.valor.toStringAsFixed(2)}'),
                        PopupMenuButton<String>(
                          onSelected: (acao) {
                            if (acao == 'editar') _abrirFormulario(gasto);
                            if (acao == 'excluir') _excluir(gasto);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'excluir',
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _graficoCategorias(List<Gasto> gastos) {
    final totais = <String, double>{};
    for (final gasto in gastos) {
      final categoria = gasto.categoria.isEmpty
          ? 'Sem categoria'
          : gasto.categoria;
      totais[categoria] = (totais[categoria] ?? 0) + gasto.valor;
    }
    if (totais.isEmpty) return const SizedBox.shrink();
    final maior = totais.values.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: totais.entries.map((entrada) {
        final proporcao = maior == 0 ? 0.0 : entrada.value / maior;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entrada.key}: R\$ ${entrada.value.toStringAsFixed(2)}'),
              const SizedBox(height: 3),
              LinearProgressIndicator(value: proporcao),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class FormularioGasto extends StatefulWidget {
  final Gasto? gasto;

  const FormularioGasto({super.key, this.gasto});

  @override
  State<FormularioGasto> createState() => _FormularioGastoState();
}

class _FormularioGastoState extends State<FormularioGasto> {
  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late final TextEditingController _data;
  late final TextEditingController _categoria;
  late final TextEditingController _tipo;
  late final TextEditingController _observacoes;

  @override
  void initState() {
    super.initState();
    final gasto = widget.gasto;
    _descricao = TextEditingController(text: gasto?.descricao);
    _valor = TextEditingController(text: gasto?.valor.toString() ?? '');
    _data = TextEditingController(text: gasto?.data ?? _hoje());
    _categoria = TextEditingController(text: gasto?.categoria);
    _tipo = TextEditingController(text: gasto?.tipo);
    _observacoes = TextEditingController(text: gasto?.observacoes);
  }

  String _hoje() {
    final data = DateTime.now();
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _data.dispose();
    _categoria.dispose();
    _tipo.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _salvar() {
    final valor = double.tryParse(_valor.text.trim().replaceAll(',', '.'));
    if (_descricao.text.trim().isEmpty ||
        _data.text.trim().isEmpty ||
        valor == null ||
        valor < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descrição, data e valor válido são obrigatórios.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Gasto(
        id: widget.gasto?.id,
        descricao: _descricao.text.trim(),
        valor: valor,
        data: _data.text.trim(),
        categoria: _categoria.text.trim(),
        tipo: _tipo.text.trim(),
        observacoes: _observacoes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gasto == null ? 'Novo gasto' : 'Editar gasto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(hintText: 'Descrição', controller: _descricao),
            const SizedBox(height: 10),
            CampoTexto(
              hintText: 'Valor',
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Data (AAAA-MM-DD)', controller: _data),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Categoria', controller: _categoria),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Tipo', controller: _tipo),
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
