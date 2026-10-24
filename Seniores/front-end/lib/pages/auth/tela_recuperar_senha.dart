import 'package:flutter/material.dart';

import '../../services/api_service.dart';

/// Recuperacao de senha: o token chega somente por e-mail via SMTP na API.
class RecuperarSenha extends StatefulWidget {
  const RecuperarSenha({super.key});

  @override
  State<RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<RecuperarSenha> {
  final _email = TextEditingController();
  final _codigo = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _api = ApiService();
  bool _ocupado = false;
  String? _mensagem;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length > 254) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }
    setState(() { _ocupado = true; _erro = null; _mensagem = null; });
    try {
      final resultado = await _api.requisicao('POST', '/users/password/solicitar',
          dados: {'email': email});
      if (mounted) { setState(() => _mensagem =
          '${resultado['mensagem'] ?? 'Confira seu e-mail.'}');
      }
    } catch (e) {
      if (mounted) { setState(() => _erro = e is ApiException
          ? e.message : 'Não foi possível solicitar a recuperação.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _redefinir() async {
    if (_codigo.text.trim().isEmpty || _novaSenha.text.length < 8 ||
        _novaSenha.text != _confirmacao.text) {
      setState(() => _erro =
          'Informe o código recebido e uma senha com pelo menos 8 caracteres, repetida corretamente.');
      return;
    }
    setState(() { _ocupado = true; _erro = null; _mensagem = null; });
    try {
      await _api.requisicao('POST', '/users/password/redefinir', dados: {
        'token': _codigo.text.trim(), 'nova_senha': _novaSenha.text,
      });
      _codigo.clear();
      _novaSenha.clear();
      _confirmacao.clear();
      if (mounted) { setState(() => _mensagem =
          'Senha alterada. Volte ao login e entre com a nova senha.');
      }
    } catch (e) {
      if (mounted) { setState(() => _erro = e is ApiException
          ? e.message : 'Não foi possível redefinir a senha.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recuperar senha')),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('1. Solicitar código',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Você receberá um código por e-mail se tiver uma conta cadastrada. ' 
            'O envio depende da configuração SMTP da equipe.'),
        const SizedBox(height: 12),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton(onPressed: _ocupado ? null : _solicitar,
            child: const Text('Enviar código por e-mail')),
        const SizedBox(height: 28),
        const Text('2. Redefinir senha',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(controller: _codigo, maxLines: 2,
          decoration: const InputDecoration(labelText: 'Código recebido',
              border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _novaSenha, obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(labelText: 'Nova senha (mínimo 8 caracteres)',
              border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _confirmacao, obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar nova senha',
              border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton(onPressed: _ocupado ? null : _redefinir,
            child: const Text('Alterar senha')),
        if (_ocupado) const Padding(padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator())),
        if (_mensagem != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: Semantics(liveRegion: true, child: Text(_mensagem!))),
        if (_erro != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: Semantics(liveRegion: true, child: Text(_erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)))),
      ]),
    )),
  );
}
