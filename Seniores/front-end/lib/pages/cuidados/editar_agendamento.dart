import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Edit all persisted consultation/exam fields without dropping unknown keys.
class EditarAgendamento extends StatefulWidget {
  const EditarAgendamento({super.key, required this.recurso, required this.id, required this.dados});
  final String recurso;
  final String id;
  final Map<String, dynamic> dados;
  @override
  State<EditarAgendamento> createState() => _EditarAgendamentoState();
}

class _EditarAgendamentoState extends State<EditarAgendamento> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _campos = {};
  late DateTime _data;
  bool _concluido = false;
  bool _salvando = false;
  String? _erro;
  bool get _consulta => widget.recurso == 'consultas';
  late final List<(String, String)> _definicoes;

  @override
  void initState() {
    super.initState();
    _definicoes = [
      (_consulta ? 'nomeDoutor' : 'nomeExame', _consulta ? 'Nome do médico' : 'Nome do exame'),
      if (_consulta) ('especialidade', 'Especialidade'),
      ('local', 'Local / estabelecimento'), ('telefone', 'Telefone'),
      ('whatsapp', 'WhatsApp'), ('cep', 'CEP'), ('logradouro', 'Logradouro'),
      ('bairro', 'Bairro'), ('cidade', 'Cidade'), ('estado', 'UF'),
      if (_consulta) ('motivo', 'Motivo da consulta'),
      if (_consulta) ('alertas', 'Alertas (separados por vírgula)'),
      if (_consulta) ('exames', 'Exames necessários (separados por vírgula)'),
    ];
    for (final (chave, _) in _definicoes) {
      final valor = widget.dados[chave];
      _campos[chave] = TextEditingController(text: valor is List ? valor.join(', ') : '${valor ?? ''}');
    }
    _data = DateTime.tryParse('${widget.dados['dataHora']}') ?? DateTime.now();
    _concluido = widget.dados[_consulta ? 'concluida' : 'concluido'] == true;
  }
  @override
  void dispose() {
    for (final campo in _campos.values) { campo.dispose(); }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _salvando = true; _erro = null; });
    final dados = <String, dynamic>{
      'dataHora': _data.toIso8601String(),
      (_consulta ? 'concluida' : 'concluido'): _concluido,
    };
    for (final (chave, _) in _definicoes) {
      final value = _campos[chave]!.text.trim();
      dados[chave] = (chave == 'alertas' || chave == 'exames')
        ? value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : value;
    }
    try {
      await ApiService().atualizarRegistro(widget.recurso, widget.id, dados);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = e is ApiException ? e.message : 'Erro ao editar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_consulta ? 'Editar consulta' : 'Editar exame')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620),
      child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
        ..._definicoes.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(controller: _campos[item.$1],
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: item.$2),
            keyboardType: item.$1 == 'telefone' || item.$1 == 'whatsapp' ? TextInputType.phone : TextInputType.text,
            maxLines: item.$1 == 'motivo' ? 3 : 1,
            validator: (v) => item.$1 == (_consulta ? 'nomeDoutor' : 'nomeExame') && (v ?? '').trim().isEmpty
                ? 'Campo obrigatório' : null))),
        ListTile(title: const Text('Data e horário'),
          subtitle: Text('${_data.day}/${_data.month}/${_data.year} '
              '${_data.hour.toString().padLeft(2, '0')}:${_data.minute.toString().padLeft(2, '0')}'),
          trailing: const Icon(Icons.calendar_today), onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _data,
              firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (d == null || !context.mounted) return;
            final h = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_data));
            if (h != null && context.mounted) {
              setState(() => _data = DateTime(d.year, d.month, d.day, h.hour, h.minute));
            }
          }),
        SwitchListTile(title: const Text('Concluído'), value: _concluido,
          onChanged: (v) => setState(() => _concluido = v)),
        if (_erro != null) Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando...' : 'Salvar alterações')),
      ])),
    )),
  );
}
