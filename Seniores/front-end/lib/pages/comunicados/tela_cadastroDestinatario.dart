import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import '../../models/destinatario.dart';
import '../../services/api_service.dart';
import '../../utils/mascaras.dart';

class CadastroDestinatario extends StatefulWidget {
  const CadastroDestinatario({super.key});

  @override
  State<CadastroDestinatario> createState() => _CadastroDestinatarioState();
}

class _CadastroDestinatarioState extends State<CadastroDestinatario>
    with DraftState<CadastroDestinatario> {
  @override
  Map<String, TextEditingController> get draftControllers => {
        'nomeController': nomeController,
        'vinculoController': vinculoController,
        'telefoneController': telefoneController
      };

  @override
  Map<String, dynamic> get draftValues => {};

  @override
  void restoreDraftValues(Map<String, dynamic> v) {}

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController vinculoController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  @override
  void dispose() {
    saveDraftBeforeDispose();
    nomeController.dispose();
    vinculoController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (nomeController.text.trim().isEmpty ||
        vinculoController.text.trim().isEmpty ||
        !RegExp(r'^\d{10,11}$')
            .hasMatch(telefoneController.text.replaceAll(RegExp(r'\D'), ''))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Informe o nome, o vínculo e um telefone com DDD.')),
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
      await clearDraft();
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
      appBar: AppBar(title: Text('Cadastrar Destinatário')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                        controller: nomeController,
                        decoration: InputDecoration(labelText: 'Nome')),
                    const SizedBox(height: 16),
                    TextField(
                        controller: vinculoController,
                        decoration: InputDecoration(labelText: 'Vínculo')),
                    const SizedBox(height: 16),
                    TextField(
                        controller: telefoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [TelefoneInputFormatter()],
                        decoration: InputDecoration(labelText: 'Telefone')),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      child: Text(_salvando ? 'Salvando...' : 'Salvar'),
                    ),
                  ],
                ))),
      ),
    );
  }
}
