import '../../services/draft_state.dart';
import 'package:flutter/material.dart';
import '../../models/destinatario.dart';
import '../../services/api_service.dart';
import '../../utils/mascaras.dart';

class CadastroDestinatario extends StatefulWidget {
  const CadastroDestinatario({super.key, this.destinatario});
  final Destinatario? destinatario;

  @override
  State<CadastroDestinatario> createState() => _CadastroDestinatarioState();
}

class _CadastroDestinatarioState extends State<CadastroDestinatario>
    with DraftState<CadastroDestinatario> {
  @override
  Map<String, TextEditingController> get draftControllers => {
        'nomeController': nomeController,
        'vinculoController': vinculoController,
        'telefoneController': telefoneController,
        'emailController': emailController,
        'cpfController': cpfController
      };

  @override
  Map<String, dynamic> get draftValues => {};

  @override
  void restoreDraftValues(Map<String, dynamic> v) {}

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController vinculoController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final d = widget.destinatario;
    if (d != null) {
      nomeController.text = d.nome;
      vinculoController.text = d.vinculo;
      telefoneController.text = d.telefone;
      emailController.text = d.email;
      cpfController.text = d.cpf;
    }
  }

  @override
  void dispose() {
    saveDraftBeforeDispose();
    nomeController.dispose();
    vinculoController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    cpfController.dispose();
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
    if (emailController.text.trim().isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Digite um e-mail válido ou deixe em branco.')));
      return;
    }
    final cpfNumeros = cpfController.text.replaceAll(RegExp(r'\D'), '');
    if (cpfNumeros.isNotEmpty && cpfNumeros.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('CPF deve conter 11 dígitos ou ficar vazio.')));
      return;
    }
    final destinatario = Destinatario(
      nome: nomeController.text.trim(),
      vinculo: vinculoController.text.trim(),
      telefone: telefoneController.text.trim(),
      email: emailController.text.trim(),
      cpf: cpfNumeros,
      id: widget.destinatario?.id,
    );
    setState(() => _salvando = true);
    try {
      if (widget.destinatario?.id != null) {
        await _apiService.atualizarRegistro('destinatarios',
            widget.destinatario!.id!, destinatario.toJson());
      } else {
        await _apiService.criarRegistro('destinatarios', destinatario.toJson());
      }
      await clearDraft();
      if (mounted) Navigator.pop(context, destinatario);
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.destinatario == null ? 'Cadastrar Destinatário' : 'Editar destinatário')),
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
                    const SizedBox(height: 16),
                    TextField(controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'E-mail (opcional, necessário para envio)')),
                    const SizedBox(height: 16),
                    TextField(controller: cpfController, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CPF (opcional)')),
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
