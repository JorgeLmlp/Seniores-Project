import 'package:flutter/material.dart';

import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class Incidentes extends StatefulWidget {
  const Incidentes({super.key});

  @override
  State<Incidentes> createState() => _IncidentesState();
}

class _IncidentesState extends State<Incidentes> {
  List<Incidente> _incidentes = [];
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
      final incidentes = await ApiService().listarIncidentes(
        SessionService.instance.pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _incidentes = incidentes;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErro(exception.message);
    } on StateError catch (exception) {
      _mostrarErro(exception.message);
    } catch (_) {
      _mostrarErro('Não foi possível carregar os incidentes.');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
    });
  }

  Future<void> _abrirFormulario([Incidente? incidente]) async {
    final resultado = await showDialog<Incidente>(
      context: context,
      builder: (_) => FormularioIncidente(incidente: incidente),
    );
    if (resultado == null || !mounted) return;
    try {
      final salvo = resultado.id == null
          ? await ApiService().criarIncidente(
              SessionService.instance.pacienteId,
              resultado,
            )
          : await ApiService().atualizarIncidente(resultado);
      if (!mounted) return;
      setState(() {
        final indice = _incidentes.indexWhere((item) => item.id == salvo.id);
        if (indice < 0) {
          _incidentes = [salvo, ..._incidentes];
        } else {
          _incidentes[indice] = salvo;
        }
      });
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível salvar o incidente.');
    }
  }

  Future<void> _excluir(Incidente incidente) async {
    if (incidente.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir incidente?'),
        content: const Text('O registro será removido do histórico.'),
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
      await ApiService().deletarIncidente(incidente.id!);
      if (!mounted) return;
      setState(
        () => _incidentes.removeWhere((item) => item.id == incidente.id),
      );
    } on ApiException catch (exception) {
      _mostrarMensagem(exception.message);
    } catch (_) {
      _mostrarMensagem('Não foi possível excluir o incidente.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Color _corGravidade(String gravidade) {
    return switch (gravidade) {
      'baixa' => Colors.green.shade700,
      'alta' => Colors.red.shade700,
      'critica' => Colors.deepPurple.shade700,
      _ => Colors.orange.shade700,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidentes')),
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
            : _incidentes.isEmpty
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 280),
                  Center(child: Text('Nenhum incidente registrado.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _incidentes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final incidente = _incidentes[index];
                  final cor = _corGravidade(incidente.gravidade);
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: cor),
                      title: Text('${incidente.tipo} • ${incidente.gravidade}'),
                      subtitle: Text(
                        '${incidente.dataHora}\n${incidente.descricao}'
                        '${incidente.resolvido ? '\nResolvido' : ''}',
                      ),
                      isThreeLine: true,
                      onTap: () => _abrirFormulario(incidente),
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _excluir(incidente),
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

class FormularioIncidente extends StatefulWidget {
  final Incidente? incidente;

  const FormularioIncidente({super.key, this.incidente});

  @override
  State<FormularioIncidente> createState() => _FormularioIncidenteState();
}

class _FormularioIncidenteState extends State<FormularioIncidente> {
  late final TextEditingController _tipo;
  late final TextEditingController _dataHora;
  late final TextEditingController _descricao;
  late final TextEditingController _providencias;
  late String _gravidade;
  late bool _resolvido;

  static const _gravidades = ['baixa', 'moderada', 'alta', 'critica'];

  @override
  void initState() {
    super.initState();
    final incidente = widget.incidente;
    _tipo = TextEditingController(text: incidente?.tipo);
    _dataHora = TextEditingController(
      text: incidente?.dataHora ?? _agoraFormatado(),
    );
    _descricao = TextEditingController(text: incidente?.descricao);
    _providencias = TextEditingController(text: incidente?.providencias);
    _gravidade = incidente?.gravidade ?? 'moderada';
    if (!_gravidades.contains(_gravidade)) _gravidade = 'moderada';
    _resolvido = incidente?.resolvido ?? false;
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
    _descricao.dispose();
    _providencias.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_tipo.text.trim().isEmpty ||
        _dataHora.text.trim().isEmpty ||
        _descricao.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipo, data/hora e descrição são obrigatórios.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Incidente(
        id: widget.incidente?.id,
        tipo: _tipo.text.trim(),
        dataHora: _dataHora.text.trim(),
        descricao: _descricao.text.trim(),
        gravidade: _gravidade,
        providencias: _providencias.text.trim(),
        resolvido: _resolvido,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.incidente == null ? 'Novo incidente' : 'Editar incidente',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CampoTexto(hintText: 'Tipo', controller: _tipo),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Data e hora', controller: _dataHora),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Descrição', controller: _descricao),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _gravidade,
              decoration: const InputDecoration(
                labelText: 'Gravidade',
                border: OutlineInputBorder(),
              ),
              items: _gravidades
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _gravidade = valor);
              },
            ),
            const SizedBox(height: 10),
            CampoTexto(hintText: 'Providências', controller: _providencias),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Resolvido'),
              value: _resolvido,
              onChanged: (valor) => setState(() => _resolvido = valor),
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
