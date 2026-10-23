import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../models/administracao_medicamento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class TelaDetalhesMedicamento extends StatefulWidget {
  final Medicamento medicamento;

  const TelaDetalhesMedicamento({super.key, required this.medicamento});

  @override
  State<TelaDetalhesMedicamento> createState() =>
      _TelaDetalhesMedicamentoState();
}

class _TelaDetalhesMedicamentoState extends State<TelaDetalhesMedicamento> {
  late final TextEditingController _nomeController;
  late final TextEditingController _dosagemController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _fabricanteController;
  late final TextEditingController _loteController;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _alertaController;
  late List<String> _horarios;
  late List<String> _alertas;
  late String _frequencia;
  late bool _alertaSonoro;
  late String _somAlerta;
  bool _salvando = false;

  static const _frequencias = ['diario', 'semanal', 'mensal'];

  @override
  void initState() {
    super.initState();
    final medicamento = widget.medicamento;
    _nomeController = TextEditingController(text: medicamento.nome);
    _dosagemController = TextEditingController(text: medicamento.dosagem);
    _descricaoController = TextEditingController(text: medicamento.descricao);
    _fabricanteController = TextEditingController(text: medicamento.fabricante);
    _loteController = TextEditingController(text: medicamento.lote);
    _quantidadeController = TextEditingController(
      text: medicamento.quantidade?.toString() ?? '',
    );
    _alertaController = TextEditingController();
    _horarios = List<String>.from(medicamento.horarios);
    _alertas = List<String>.from(medicamento.alertas);
    _frequencia = Medicamento.normalizarFrequencia(medicamento.frequencia);
    _alertaSonoro = medicamento.alertaSonoro;
    _somAlerta = medicamento.somAlerta ?? 'campainha';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _descricaoController.dispose();
    _fabricanteController.dispose();
    _loteController.dispose();
    _quantidadeController.dispose();
    _alertaController.dispose();
    super.dispose();
  }

  Future<void> _adicionarHorario() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (horario == null || !mounted) return;
    final valor =
        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
    if (!_horarios.contains(valor)) {
      setState(() => _horarios.add(valor));
    }
  }

  void _adicionarAlerta() {
    final alerta = _alertaController.text.trim();
    if (alerta.isEmpty || _alertas.contains(alerta)) return;
    setState(() {
      _alertas.add(alerta);
      _alertaController.clear();
    });
  }

  Medicamento _modeloEditado() {
    return Medicamento(
      id: widget.medicamento.id,
      nome: _nomeController.text.trim(),
      dosagem: _dosagemController.text.trim(),
      frequencia: _frequencia,
      horarios: List<String>.from(_horarios),
      alertas: List<String>.from(_alertas),
      descricao: _descricaoController.text.trim(),
      fabricante: _fabricanteController.text.trim(),
      lote: _loteController.text.trim(),
      quantidade: int.tryParse(_quantidadeController.text.trim()),
      alertaSonoro: _alertaSonoro,
      somAlerta: _somAlerta,
    );
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty ||
        _dosagemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e dosagem são obrigatórios.')),
      );
      return;
    }
    if (_quantidadeController.text.trim().isNotEmpty &&
        int.tryParse(_quantidadeController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantidade deve ser um número inteiro.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizado = await ApiService().atualizarMedicamento(
        _modeloEditado(),
      );
      if (!mounted) return;
      Navigator.pop(context, atualizado);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir medicamento?'),
        content: Text(
          'O medicamento ${widget.medicamento.nome} será removido.',
        ),
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

    setState(() => _salvando = true);
    try {
      await ApiService().deletarMedicamento(widget.medicamento.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do medicamento'),
        actions: [
          IconButton(
            tooltip: 'Confirmar dose',
            onPressed: _salvando ? null : _confirmarDose,
            icon: const Icon(Icons.check_circle_outline),
          ),
          IconButton(
            tooltip: 'Excluir medicamento',
            onPressed: _salvando ? null : _excluir,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CampoTexto(hintText: 'Nome', controller: _nomeController),
          const SizedBox(height: 12),
          CampoTexto(hintText: 'Dosagem', controller: _dosagemController),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _frequencia,
            decoration: const InputDecoration(
              labelText: 'Frequência',
              border: OutlineInputBorder(),
            ),
            items: _frequencias
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: _salvando
                ? null
                : (value) {
                    if (value != null) setState(() => _frequencia = value);
                  },
          ),
          const SizedBox(height: 16),
          const Text(
            'Horários',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Wrap(
            spacing: 8,
            children: [
              ..._horarios.map(
                (horario) => InputChip(
                  label: Text(horario),
                  onDeleted: _salvando
                      ? null
                      : () => setState(() => _horarios.remove(horario)),
                ),
              ),
              ActionChip(
                label: const Text('Adicionar horário'),
                onPressed: _salvando ? null : _adicionarHorario,
              ),
            ],
          ),
          const SizedBox(height: 16),
          CampoTexto(hintText: 'Descrição', controller: _descricaoController),
          const SizedBox(height: 12),
          CampoTexto(hintText: 'Fabricante', controller: _fabricanteController),
          const SizedBox(height: 12),
          CampoTexto(hintText: 'Lote', controller: _loteController),
          const SizedBox(height: 12),
          CampoTexto(
            hintText: 'Quantidade',
            controller: _quantidadeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CampoTexto(
                  hintText: 'Novo alerta',
                  controller: _alertaController,
                ),
              ),
              IconButton(
                onPressed: _salvando ? null : _adicionarAlerta,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: _alertas
                .map(
                  (alerta) => InputChip(
                    label: Text(alerta),
                    onDeleted: _salvando
                        ? null
                        : () => setState(() => _alertas.remove(alerta)),
                  ),
                )
                .toList(),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Alerta sonoro'),
            value: _alertaSonoro,
            onChanged: _salvando
                ? null
                : (value) => setState(() => _alertaSonoro = value),
          ),
          if (_alertaSonoro)
            DropdownButtonFormField<String>(
              initialValue: _somAlerta,
              decoration: const InputDecoration(
                labelText: 'Som do alerta',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'campainha', child: Text('Campainha')),
                DropdownMenuItem(value: 'suave', child: Text('Suave')),
                DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
              ],
              onChanged: _salvando
                  ? null
                  : (value) {
                      if (value != null) setState(() => _somAlerta = value);
                    },
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _salvando ? null : _abrirHistoricoDoses,
            icon: const Icon(Icons.history),
            label: const Text('Histórico de doses'),
          ),
          const SizedBox(height: 12),
          Botao(
            texto: _salvando ? 'Salvando...' : 'Salvar alterações',
            altura: 48,
            onPressed: _salvando ? () {} : _salvar,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarDose() async {
    final responsaveis = await _carregarResponsaveis();
    if (!mounted) return;
    final horarioPadrao = _horarios.isEmpty
        ? TimeOfDay.now().format(context)
        : _horarios.first;
    final dados = await showDialog<_DoseFormResult>(
      context: context,
      builder: (_) => _DoseDialog(
        horarios: _horarios.isEmpty ? [horarioPadrao] : _horarios,
        responsaveis: responsaveis,
      ),
    );
    if (dados == null || !mounted) return;
    try {
      await ApiService().registrarAdministracao(
        AdministracaoMedicamento(
          medicamentoId: widget.medicamento.id!,
          horario: dados.horario,
          responsavelId: dados.responsavelId,
          observacao: dados.observacao,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dose confirmada com sucesso.')),
        );
      }
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  Future<List<UsuarioVinculado>> _carregarResponsaveis() async {
    try {
      return await ApiService().listarResponsaveisVinculados(
        SessionService.instance.pacienteId,
      );
    } on ApiException {
      return [];
    }
  }

  Future<void> _abrirHistoricoDoses() async {
    try {
      final doses = await ApiService().listarAdministracoes(
        widget.medicamento.id!,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => doses.isEmpty
            ? const SizedBox(
                height: 180,
                child: Center(child: Text('Nenhuma dose confirmada.')),
              )
            : ListView.builder(
                itemCount: doses.length,
                itemBuilder: (_, index) {
                  final dose = doses[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text('Horário ${dose.horario}'),
                    subtitle: Text(
                      '${dose.administradoEm ?? ''}${dose.observacao.isEmpty ? '' : '\n${dose.observacao}'}',
                    ),
                  );
                },
              ),
      );
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }
}

class _DoseFormResult {
  final String horario;
  final int? responsavelId;
  final String observacao;

  const _DoseFormResult(this.horario, this.responsavelId, this.observacao);
}

class _DoseDialog extends StatefulWidget {
  final List<String> horarios;
  final List<UsuarioVinculado> responsaveis;

  const _DoseDialog({required this.horarios, required this.responsaveis});

  @override
  State<_DoseDialog> createState() => _DoseDialogState();
}

class _DoseDialogState extends State<_DoseDialog> {
  late String _horario;
  int? _responsavelId;
  final _observacao = TextEditingController();

  @override
  void initState() {
    super.initState();
    _horario = widget.horarios.first;
  }

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar dose'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _horario,
              decoration: const InputDecoration(labelText: 'Horário'),
              items: widget.horarios
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _horario = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _responsavelId,
              decoration: const InputDecoration(labelText: 'Responsável'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Não informado'),
                ),
                ...widget.responsaveis.map(
                  (item) => DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.nome),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _responsavelId = value),
            ),
            const SizedBox(height: 12),
            CampoTexto(hintText: 'Observação', controller: _observacao),
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
            _DoseFormResult(_horario, _responsavelId, _observacao.text.trim()),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
