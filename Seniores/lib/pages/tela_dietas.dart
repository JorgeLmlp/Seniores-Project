import 'package:flutter/material.dart';

import '../models/dieta.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Dietas extends StatefulWidget {
  const Dietas({super.key});

  @override
  State<Dietas> createState() => _DietasState();
}

class _DietasState extends State<Dietas> {
  List<Dieta> _dietas = [];
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
      final dietas = await ApiService().listarDietas(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _dietas = dietas;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar as dietas.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirFormulario([Dieta? dieta]) async {
    final resultado = await showDialog<Dieta>(
      context: context,
      builder: (_) => FormularioDieta(dieta: dieta),
    );
    if (resultado == null || !mounted) return;
    try {
      final salvo = resultado.id == null
          ? await ApiService().criarDieta(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await ApiService().atualizarDieta(resultado);
      if (!mounted) return;
      setState(() {
        final indice = _dietas.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _dietas = [salvo, ..._dietas];
        } else {
          _dietas[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar a dieta.');
    }
  }

  Future<void> _excluir(Dieta dieta) async {
    if (dieta.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir dieta?'),
        content: const Text('O plano alimentar será removido.'),
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
      await ApiService().deletarDieta(dieta.id!);
      if (mounted) setState(() => _dietas.removeWhere((item) => item.id == dieta.id));
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dietas e restrições')),
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
            : _dietas.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Nenhuma dieta cadastrada.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _dietas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final dieta = _dietas[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        dieta.ativa ? Icons.restaurant : Icons.restaurant_outlined,
                        color: dieta.ativa ? Colors.green : Colors.grey,
                      ),
                      title: Text('${dieta.tipo}${dieta.ativa ? '' : ' (inativa)'}'),
                      subtitle: Text(
                        '${dieta.dataInicio}\n${dieta.descricao}'
                        '${dieta.restricoes.isEmpty ? '' : '\nRestrições: ${dieta.restricoes}'}',
                      ),
                      isThreeLine: dieta.restricoes.isNotEmpty,
                      onTap: () => _abrirFormulario(dieta),
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _excluir(dieta),
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

class FormularioDieta extends StatefulWidget {
  final Dieta? dieta;

  const FormularioDieta({super.key, this.dieta});

  @override
  State<FormularioDieta> createState() => _FormularioDietaState();
}

class _FormularioDietaState extends State<FormularioDieta> {
  late final TextEditingController _tipo;
  late final TextEditingController _dataInicio;
  late final TextEditingController _descricao;
  late final TextEditingController _restricoes;
  late final TextEditingController _observacoes;
  late bool _ativa;

  @override
  void initState() {
    super.initState();
    final dieta = widget.dieta;
    _tipo = TextEditingController(text: dieta?.tipo);
    _dataInicio = TextEditingController(
      text: dieta?.dataInicio ?? _dataAtual(),
    );
    _descricao = TextEditingController(text: dieta?.descricao);
    _restricoes = TextEditingController(text: dieta?.restricoes);
    _observacoes = TextEditingController(text: dieta?.observacoes);
    _ativa = dieta?.ativa ?? true;
  }

  String _dataAtual() {
    final agora = DateTime.now();
    return '${agora.year.toString().padLeft(4, '0')}-'
        '${agora.month.toString().padLeft(2, '0')}-'
        '${agora.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tipo.dispose();
    _dataInicio.dispose();
    _descricao.dispose();
    _restricoes.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_tipo.text.trim().isEmpty ||
        _dataInicio.text.trim().isEmpty ||
        _descricao.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipo, data de início e descrição são obrigatórios.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Dieta(
        id: widget.dieta?.id,
        tipo: _tipo.text.trim(),
        dataInicio: _dataInicio.text.trim(),
        descricao: _descricao.text.trim(),
        restricoes: _restricoes.text.trim(),
        observacoes: _observacoes.text.trim(),
        ativa: _ativa,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dieta == null ? 'Nova dieta' : 'Editar dieta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(hintText: 'Tipo de dieta', controller: _tipo),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Data de início', controller: _dataInicio),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Descrição', controller: _descricao),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Restrições alimentares', controller: _restricoes),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Observações', controller: _observacoes),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dieta ativa'),
              value: _ativa,
              onChanged: (valor) => setState(() => _ativa = valor),
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
