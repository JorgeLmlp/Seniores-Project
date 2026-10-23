import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/custom_botao.dart';
import '../widgets/custom_textField.dart';

class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  bool _solicitando = false;
  bool _redefinindo = false;
  bool _mostrarRedefinicao = false;
  String? _mensagem;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _novaSenha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _solicitando = true;
      _erro = null;
      _mensagem = null;
    });
    try {
      final resposta = await ApiService().solicitarRecuperacaoSenha(
        email: email,
      );
      if (!mounted) return;
      setState(() {
        _mensagem = resposta['mensagem']?.toString();
        _mostrarRedefinicao = true;
        final tokenLocal = resposta['token_desenvolvimento']?.toString();
        if (tokenLocal != null) _token.text = tokenLocal;
      });
    } on ApiException catch (exception) {
      if (mounted) setState(() => _erro = exception.message);
    } finally {
      if (mounted) setState(() => _solicitando = false);
    }
  }

  Future<void> _redefinir() async {
    final token = _token.text.trim();
    final senha = _novaSenha.text;
    if (token.isEmpty || senha.length < 6 || senha != _confirmarSenha.text) {
      setState(() => _erro = 'Confira o código e as senhas informadas.');
      return;
    }
    setState(() {
      _redefinindo = true;
      _erro = null;
      _mensagem = null;
    });
    try {
      await ApiService().redefinirSenha(token: token, novaSenha: senha);
      if (!mounted) return;
      setState(() {
        _mensagem = 'Senha redefinida. Você já pode voltar e entrar.';
        _mostrarRedefinicao = false;
        _token.clear();
        _novaSenha.clear();
        _confirmarSenha.clear();
      });
    } on ApiException catch (exception) {
      if (mounted) setState(() => _erro = exception.message);
    } finally {
      if (mounted) setState(() => _redefinindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe seu e-mail para receber as instruções de redefinição.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 18),
              CampoTexto(
                hintText: 'E-mail',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 14),
              Botao(
                texto: _solicitando ? 'Enviando...' : 'Enviar instruções',
                onPressed: _solicitando ? () {} : _solicitar,
              ),
              if (_mensagem != null) ...[
                const SizedBox(height: 16),
                Text(_mensagem!, style: const TextStyle(color: Colors.green)),
              ],
              if (_mostrarRedefinicao) ...[
                const Divider(height: 32),
                const Text(
                  'Cole o código recebido por e-mail para escolher uma nova senha.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                CampoTexto(
                  hintText: 'Código de recuperação',
                  controller: _token,
                ),
                const SizedBox(height: 12),
                CampoTexto(
                  hintText: 'Nova senha',
                  controller: _novaSenha,
                  senha: true,
                ),
                const SizedBox(height: 12),
                CampoTexto(
                  hintText: 'Confirmar nova senha',
                  controller: _confirmarSenha,
                  senha: true,
                ),
                const SizedBox(height: 14),
                Botao(
                  texto: _redefinindo ? 'Salvando...' : 'Redefinir senha',
                  onPressed: _redefinindo ? () {} : _redefinir,
                ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
