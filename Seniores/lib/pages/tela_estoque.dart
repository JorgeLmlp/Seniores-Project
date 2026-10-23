import 'package:flutter/material.dart';

import '../models/item_estoque.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Estoque extends StatefulWidget {
  final int? itemId;

  const Estoque({super.key, this.itemId});

  @override
  State<Estoque> createState() => _EstoqueState();
}

class _EstoqueState extends State<Estoque> {
  List<ItemEstoque> _itens = [];
  bool _carregando = true;
  String? _erro;
  bool _itemInicialAberto = false;

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
      final itens = await ApiService().listarEstoque(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _carregando = false;
      });
      final itemInicial = widget.itemId == null
          ? null
          : itens.where((item) => item.id == widget.itemId).firstOrNull;
      if (itemInicial != null && !_itemInicialAberto) {
        _itemInicialAberto = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _abrirFormulario(itemInicial);
        });
      }
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar o estoque.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirFormulario([ItemEstoque? item]) async {
    final resultado = await showDialog<ItemEstoque>(
      context: context,
      builder: (_) => FormularioEstoque(item: item),
    );
    if (resultado == null || !mounted) return;
    try {
      final salvo = resultado.id == null
          ? await ApiService().criarItemEstoque(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await ApiService().atualizarItemEstoque(resultado);
      if (!mounted) return;
      setState(() {
        final indice = _itens.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _itens = [..._itens, salvo];
        } else {
          _itens[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar o item.');
    }
  }

  Future<void> _ajustar(ItemEstoque item, int delta) async {
    final novaQuantidade = (item.quantidade + delta).clamp(0, 1000000);
    if (novaQuantidade == item.quantidade) return;
    final atualizado = ItemEstoque(
      id: item.id,
      nome: item.nome,
      categoria: item.categoria,
      quantidade: novaQuantidade,
      quantidadeMinima: item.quantidadeMinima,
      unidade: item.unidade,
      observacoes: item.observacoes,
      atualizadoEm: item.atualizadoEm,
    );
    try {
      final salvo = await ApiService().atualizarItemEstoque(atualizado);
      if (!mounted) return;
      setState(() {
        final indice = _itens.indexWhere((item) => item.id == salvo.id);
        if (indice >= 0) _itens[indice] = salvo;
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível ajustar a quantidade.');
    }
  }

  Future<void> _excluir(ItemEstoque item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir item?'),
        content: Text('O item ${item.nome} será removido do estoque.'),
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
    if (confirmar != true || item.id == null || !mounted) return;
    try {
      await ApiService().deletarItemEstoque(item.id!);
      if (!mounted) return;
      setState(() => _itens.removeWhere((atual) => atual.id == item.id));
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível excluir o item.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Estoque')),
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
            : _itens.isEmpty
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 280),
                  Center(child: Text('Nenhum item cadastrado no estoque.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _itens.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _card(_itens[index]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _card(ItemEstoque item) {
    final cor = item.estoqueBaixo ? Colors.red.shade700 : Colors.green.shade700;
    final quantidadeTexto = '${item.quantidade} ${item.unidade}'.trim();
    return Card(
      child: ListTile(
        leading: Icon(Icons.inventory_2_outlined, color: cor),
        title: Text(item.nome),
        subtitle: Text(
          '$quantidadeTexto disponíveis • mínimo ${item.quantidadeMinima}'
          '${item.estoqueBaixo ? ' • estoque baixo' : ''}',
          style: TextStyle(color: item.estoqueBaixo ? cor : null),
        ),
        isThreeLine: item.estoqueBaixo,
        trailing: SizedBox(
          width: 132,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Diminuir',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _ajustar(item, -1),
              ),
              IconButton(
                tooltip: 'Aumentar',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _ajustar(item, 1),
              ),
              PopupMenuButton<String>(
                onSelected: (acao) {
                  if (acao == 'editar') _abrirFormulario(item);
                  if (acao == 'excluir') _excluir(item);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioEstoque extends StatefulWidget {
  final ItemEstoque? item;

  const FormularioEstoque({super.key, this.item});

  @override
  State<FormularioEstoque> createState() => _FormularioEstoqueState();
}

class _FormularioEstoqueState extends State<FormularioEstoque> {
  late final TextEditingController _nome;
  late final TextEditingController _categoria;
  late final TextEditingController _quantidade;
  late final TextEditingController _minimo;
  late final TextEditingController _unidade;
  late final TextEditingController _observacoes;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nome = TextEditingController(text: item?.nome);
    _categoria = TextEditingController(text: item?.categoria);
    _quantidade = TextEditingController(
      text: item?.quantidade.toString() ?? '0',
    );
    _minimo = TextEditingController(
      text: item?.quantidadeMinima.toString() ?? '0',
    );
    _unidade = TextEditingController(text: item?.unidade);
    _observacoes = TextEditingController(text: item?.observacoes);
  }

  @override
  void dispose() {
    _nome.dispose();
    _categoria.dispose();
    _quantidade.dispose();
    _minimo.dispose();
    _unidade.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _nome.text.trim();
    final quantidade = int.tryParse(_quantidade.text.trim());
    final minimo = int.tryParse(_minimo.text.trim());
    if (nome.isEmpty ||
        quantidade == null ||
        minimo == null ||
        quantidade < 0 ||
        minimo < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e quantidades válidas.')),
      );
      return;
    }
    Navigator.pop(
      context,
      ItemEstoque(
        id: widget.item?.id,
        nome: nome,
        categoria: _categoria.text.trim(),
        quantidade: quantidade,
        quantidadeMinima: minimo,
        unidade: _unidade.text.trim(),
        observacoes: _observacoes.text.trim(),
        atualizadoEm: widget.item?.atualizadoEm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Novo item' : 'Editar item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(hintText: 'Nome', controller: _nome),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Categoria', controller: _categoria),
            const SizedBox(height: 10),
            CampoTexto(
              hintText: 'Quantidade atual',
              controller: _quantidade,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            CampoTexto(
              hintText: 'Quantidade mínima',
              controller: _minimo,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Unidade', controller: _unidade),
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
