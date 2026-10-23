import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';
import 'tela_login.dart';

class MinhaConta extends StatefulWidget {
  const MinhaConta({super.key});

  @override
  State<MinhaConta> createState() => _MinhaContaState();
}

class _MinhaContaState extends State<MinhaConta> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _idadeController = TextEditingController();
  final _sangueController = TextEditingController();
  final _preferenciasController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _idadeController.dispose();
    _sangueController.dispose();
    _preferenciasController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final dados = await ApiService().obterUsuario(
        tipo: SessionService.instance.tipoUsuario!,
        usuarioId: SessionService.instance.usuarioId!,
      );
      if (!mounted) return;
      _nomeController.text = (dados['name'] ?? '').toString();
      _emailController.text = (dados['email'] ?? '').toString();
      _telefoneController.text = (dados['phoneNumber'] ?? '').toString();
      _cpfController.text = (dados['cpf'] ?? '').toString();
      _idadeController.text = (dados['idade'] ?? '').toString();
      _sangueController.text = (dados['tipo_sanguineo'] ?? '').toString();
      _preferenciasController.text = (dados['preferencias'] ?? '').toString();
      setState(() => _carregando = false);
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _erro = exception.message;
          _carregando = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final dados = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'cpf': _cpfController.text.trim(),
      if (_idadeController.text.trim().isNotEmpty)
        'idade': int.tryParse(_idadeController.text.trim()),
      'tipo_sanguineo': _sangueController.text.trim(),
      'preferencias': _preferenciasController.text.trim(),
      if (_senhaController.text.isNotEmpty) 'senha': _senhaController.text,
    };
    try {
      final atualizado = await ApiService().atualizarUsuario(
        tipo: SessionService.instance.tipoUsuario!,
        usuarioId: SessionService.instance.usuarioId!,
        dados: dados,
      );
      await SessionService.instance.atualizarDados(
        nome: atualizado['name']?.toString(),
        email: atualizado['email']?.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Conta atualizada.')));
      }
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text('Essa ação não poderá ser desfeita.'),
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
    if (confirmar != true) return;
    try {
      await ApiService().deletarUsuario(
        tipo: SessionService.instance.tipoUsuario!,
        usuarioId: SessionService.instance.usuarioId!,
      );
      await SessionService.instance.encerrar();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(child: Text(_erro!, textAlign: TextAlign.center))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                CampoTexto(hintText: 'Nome', controller: _nomeController),
                const SizedBox(height: 16),
                CampoTexto(
                  hintText: 'E-mail',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  hintText: 'Telefone',
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CampoTexto(hintText: 'CPF', controller: _cpfController),
                const SizedBox(height: 16),
                CampoTexto(
                  hintText: 'Idade',
                  controller: _idadeController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  hintText: 'Tipo sanguíneo',
                  controller: _sangueController,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  hintText: 'Preferências',
                  controller: _preferenciasController,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  hintText: 'Nova senha (opcional)',
                  controller: _senhaController,
                  senha: true,
                ),
                const SizedBox(height: 24),
                Botao(
                  texto: _salvando ? 'Salvando...' : 'Salvar alterações',
                  onPressed: _salvando ? () {} : _salvar,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _excluir,
                  child: const Text('Excluir minha conta'),
                ),
              ],
            ),
    );
  }
}
