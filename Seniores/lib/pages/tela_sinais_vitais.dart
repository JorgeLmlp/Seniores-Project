import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sinal_vital.dart';
import '../services/api_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class SinaisVitais extends StatefulWidget {
  const SinaisVitais({super.key});

  @override
  State<SinaisVitais> createState() => _SinaisVitaisState();
}

class _SinaisVitaisState extends State<SinaisVitais> {
  final _pressao = TextEditingController();
  final _glicemia = TextEditingController();
  final _temperatura = TextEditingController();
  final _frequencia = TextEditingController();
  final _saturacao = TextEditingController();
  List<SinalVital> _historico = [];
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  String _tipoFiltro = 'Todos';
  String _periodoFiltro = 'Todos';

  static const _tipos = [
    'Todos',
    'Pressão',
    'Glicemia',
    'Temperatura',
    'Frequência cardíaca',
    'Saturação',
  ];
  static const _periodos = ['Todos', '7 dias', '30 dias', '90 dias'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pressao.dispose();
    _glicemia.dispose();
    _temperatura.dispose();
    _frequencia.dispose();
    _saturacao.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final historico = await ApiService().listarSinaisVitais();
      if (!mounted) return;
      setState(() {
        _historico = historico;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      _mostrarErroCarregamento(exception.message);
    } catch (_) {
      _mostrarErroCarregamento(
        'Não foi possível carregar as medições. Tente novamente.',
      );
    }
  }

  void _mostrarErroCarregamento(String mensagem) {
    if (!mounted) return;
    setState(() {
      _erro = mensagem;
      _carregando = false;
    });
  }

  SinalVital _sinalDoFormulario() {
    return SinalVital(
      data: DateTime.now(),
      pressao: _pressao.text.trim(),
      glicemia: _glicemia.text.trim(),
      temperatura: _temperatura.text.trim(),
      frequenciaCardiaca: _frequencia.text.trim(),
      saturacao: _saturacao.text.trim(),
    );
  }

  Future<void> _salvar() async {
    final sinal = _sinalDoFormulario();
    final erroValidacao = SinalVitalValidation.validar(sinal);
    if (erroValidacao != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(erroValidacao)));
      return;
    }

    setState(() => _salvando = true);
    try {
      final salvo = await ApiService().criarSinalVital(sinal);
      if (!mounted) return;
      setState(() => _historico = [salvo, ..._historico]);
      for (final controller in [
        _pressao,
        _glicemia,
        _temperatura,
        _frequencia,
        _saturacao,
      ]) {
        controller.clear();
      }
    } on ApiException catch (exception) {
      _mostrarErroAcao(exception.message);
    } catch (_) {
      _mostrarErroAcao('Não foi possível salvar a medição.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarErroAcao(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _excluir(SinalVital sinal) async {
    if (sinal.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir medição?'),
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
      await ApiService().deletarSinalVital(sinal.id!);
      if (!mounted) return;
      setState(() => _historico.removeWhere((item) => item.id == sinal.id));
    } on ApiException catch (exception) {
      _mostrarErroAcao(exception.message);
    } catch (_) {
      _mostrarErroAcao('Não foi possível excluir a medição.');
    }
  }

  Future<void> _editar(SinalVital sinal) async {
    final pressao = TextEditingController(text: sinal.pressao);
    final glicemia = TextEditingController(text: sinal.glicemia);
    final temperatura = TextEditingController(text: sinal.temperatura);
    final frequencia = TextEditingController(text: sinal.frequenciaCardiaca);
    final saturacao = TextEditingController(text: sinal.saturacao);
    final editado = await showDialog<SinalVital>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar medição'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pressao,
                decoration: const InputDecoration(labelText: 'Pressão (mmHg)'),
              ),
              TextField(
                controller: glicemia,
                decoration: const InputDecoration(
                  labelText: 'Glicemia (mg/dL)',
                ),
              ),
              TextField(
                controller: temperatura,
                decoration: const InputDecoration(
                  labelText: 'Temperatura (°C)',
                ),
              ),
              TextField(
                controller: frequencia,
                decoration: const InputDecoration(
                  labelText: 'Frequência cardíaca (bpm)',
                ),
              ),
              TextField(
                controller: saturacao,
                decoration: const InputDecoration(labelText: 'Saturação (%)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              SinalVital(
                id: sinal.id,
                data: sinal.data,
                pressao: pressao.text.trim(),
                glicemia: glicemia.text.trim(),
                temperatura: temperatura.text.trim(),
                frequenciaCardiaca: frequencia.text.trim(),
                saturacao: saturacao.text.trim(),
              ),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    for (final controller in [
      pressao,
      glicemia,
      temperatura,
      frequencia,
      saturacao,
    ]) {
      controller.dispose();
    }
    if (editado == null || sinal.id == null || !mounted) return;
    final erroValidacao = SinalVitalValidation.validar(editado);
    if (erroValidacao != null) {
      _mostrarErroAcao(erroValidacao);
      return;
    }
    try {
      await ApiService().atualizarSinalVital(sinal.id!, editado);
      if (!mounted) return;
      setState(() {
        _historico = _historico
            .map((item) => item.id == editado.id ? editado : item)
            .toList();
      });
    } on ApiException catch (exception) {
      _mostrarErroAcao(exception.message);
    } catch (_) {
      _mostrarErroAcao('Não foi possível atualizar a medição.');
    }
  }

  List<SinalVital> get _filtrados {
    final limite = switch (_periodoFiltro) {
      '7 dias' => DateTime.now().subtract(const Duration(days: 7)),
      '30 dias' => DateTime.now().subtract(const Duration(days: 30)),
      '90 dias' => DateTime.now().subtract(const Duration(days: 90)),
      _ => null,
    };
    final resultado = _historico.where((sinal) {
      if (limite != null &&
          (sinal.data == null || sinal.data!.isBefore(limite))) {
        return false;
      }
      return _temTipo(sinal, _tipoFiltro);
    }).toList();
    resultado.sort(
      (a, b) => (b.data ?? DateTime(0)).compareTo(a.data ?? DateTime(0)),
    );
    return resultado;
  }

  bool _temTipo(SinalVital sinal, String tipo) {
    return switch (tipo) {
      'Pressão' => sinal.pressao?.trim().isNotEmpty == true,
      'Glicemia' => sinal.glicemia?.trim().isNotEmpty == true,
      'Temperatura' => sinal.temperatura?.trim().isNotEmpty == true,
      'Frequência cardíaca' =>
        sinal.frequenciaCardiaca?.trim().isNotEmpty == true,
      'Saturação' => sinal.saturacao?.trim().isNotEmpty == true,
      _ => true,
    };
  }

  double? _valorDoTipo(SinalVital sinal) {
    final valor = switch (_tipoFiltro) {
      'Pressão' => sinal.pressao?.split('/').first,
      'Glicemia' => sinal.glicemia,
      'Temperatura' => sinal.temperatura,
      'Frequência cardíaca' => sinal.frequenciaCardiaca,
      'Saturação' => sinal.saturacao,
      _ => null,
    };
    if (valor == null) return null;
    return double.tryParse(
      valor.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
  }

  Widget _grafico() {
    if (_tipoFiltro == 'Todos') {
      return const Text(
        'Selecione um tipo de medida para visualizar a tendência.',
      );
    }
    final valores = _filtrados.reversed
        .map(_valorDoTipo)
        .whereType<double>()
        .toList();
    if (valores.isEmpty) {
      return const Text('Sem dados para o filtro selecionado.');
    }
    final menor = valores.reduce(math.min);
    final maior = valores.reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(painter: _TendenciaPainter(valores)),
        ),
        Text(
          'Mínimo: ${menor.toStringAsFixed(1)}  |  Máximo: ${maior.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    return Scaffold(
      appBar: AppBar(title: const Text('Sinais vitais')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            CampoTexto(hintText: 'Pressão (ex.: 120/80)', controller: _pressao),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Glicemia (mg/dL)',
              controller: _glicemia,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Temperatura (°C)',
              controller: _temperatura,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Frequência cardíaca (bpm)',
              controller: _frequencia,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              hintText: 'Saturação (%)',
              controller: _saturacao,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Botao(
              texto: _salvando ? 'Salvando...' : 'Salvar medição',
              onPressed: _salvando ? () {} : _salvar,
            ),
            const SizedBox(height: 24),
            const Text(
              'Evolução',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _tipoFiltro,
              decoration: const InputDecoration(
                labelText: 'Tipo de medida',
                border: OutlineInputBorder(),
              ),
              items: _tipos
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _tipoFiltro = valor);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _periodoFiltro,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
              ),
              items: _periodos
                  .map(
                    (periodo) =>
                        DropdownMenuItem(value: periodo, child: Text(periodo)),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _periodoFiltro = valor);
              },
            ),
            const SizedBox(height: 12),
            _grafico(),
            const SizedBox(height: 24),
            const Text(
              'Histórico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
              const Text('Nenhuma medição encontrada para os filtros.')
            else
              ...filtrados.map(
                (sinal) => Card(
                  child: ListTile(
                    title: Text(sinal.resumo),
                    subtitle: Text(sinal.data?.toLocal().toString() ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editar(sinal),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _excluir(sinal),
                        ),
                      ],
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

class _TendenciaPainter extends CustomPainter {
  final List<double> valores;

  _TendenciaPainter(this.valores);

  @override
  void paint(Canvas canvas, Size size) {
    final grade = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final linha = Paint()
      ..color = const Color(0xFF275DAD)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final ponto = Paint()..color = const Color(0xFF275DAD);
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }
    final minimo = valores.reduce(math.min);
    final maximo = valores.reduce(math.max);
    final intervalo = maximo - minimo == 0 ? 1 : maximo - minimo;
    final caminho = Path();
    for (var i = 0; i < valores.length; i++) {
      final x = valores.length == 1
          ? size.width / 2
          : size.width * i / (valores.length - 1);
      final y = size.height - ((valores[i] - minimo) / intervalo * size.height);
      final pontoAtual = Offset(x, y);
      if (i == 0) {
        caminho.moveTo(x, y);
      } else {
        caminho.lineTo(x, y);
      }
      canvas.drawCircle(pontoAtual, 5, ponto);
    }
    canvas.drawPath(caminho, linha);
  }

  @override
  bool shouldRepaint(covariant _TendenciaPainter oldDelegate) =>
      oldDelegate.valores != valores;
}
