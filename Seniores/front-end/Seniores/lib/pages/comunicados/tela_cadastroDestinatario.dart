import 'package:flutter/material.dart';
import '../../models/destinatario.dart';
import '../../services/api_service.dart';

class CadastroDestinatario extends StatefulWidget {
  const CadastroDestinatario({super.key});

  @override
  State<CadastroDestinatario> createState() => _CadastroDestinatarioState();
}

class _CadastroDestinatarioState extends State<CadastroDestinatario> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController vinculoController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  @override
  void dispose() {
    nomeController.dispose();
    vinculoController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (nomeController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome e o telefone.')),
      );
      return;
    }
    final destinatario = Destinatario(
      nome: nomeController.text.trim(),
      vinculo: vinculoController.text.trim(),
      telefone: telefoneController.text.trim(),
    );
    setState(() => _salvando = true);
    try {
      await _apiService.criarRegistro('destinatarios', destinatario.toJson());
      if (mounted) Navigator.pop(context, destinatario);
    } on ApiException catch (erro) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Destinatário')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome')),
            TextField(
                controller: vinculoController,
                decoration: const InputDecoration(labelText: 'Vínculo')),
            TextField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
