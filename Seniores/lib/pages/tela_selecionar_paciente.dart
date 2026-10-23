import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class SelecionarPaciente extends StatefulWidget {
  const SelecionarPaciente({super.key});

  @override
  State<SelecionarPaciente> createState() => _SelecionarPacienteState();
}

class _SelecionarPacienteState extends State<SelecionarPaciente> {
  bool _carregando = true;
  String? _erro;
  List<UsuarioVinculado> _pacientes = [];

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
      final pacientes = await ApiService().listarPacientesVinculados();
      if (!mounted) return;
      setState(() {
        _pacientes = pacientes;
        _carregando = false;
      });
    } on ApiException catch (exception) {
      if (mounted) setState(() => _erro = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível carregar os pacientes.');
      }
    }
  }

  Future<void> _selecionar(UsuarioVinculado paciente) async {
    await SessionService.instance.selecionarPaciente(
      paciente.id,
      paciente.nome,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar paciente')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _pacientes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum paciente vinculado a esta conta.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _pacientes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final paciente = _pacientes[index];
                final selecionado =
                    SessionService.instance.pacienteSelecionadoId ==
                    paciente.id;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      selecionado ? Icons.radio_button_checked : Icons.person,
                      color: selecionado ? Colors.blue : null,
                    ),
                    title: Text(paciente.nome),
                    subtitle: Text(paciente.email),
                    onTap: () => _selecionar(paciente),
                  ),
                );
              },
            ),
    );
  }
}
