import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/local_store.dart';
import '../services/app_settings.dart';
import '../utils/mascaras.dart';
import 'auth/tela_login.dart';

Future<void> sairDaConta(BuildContext context) async {
  final scope = SessionService.instance.escopo;
  SessionService.instance.encerrar();
  try {
    await LocalStore.instance.clear(scope);
  } finally {
    if (context.mounted)
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Login()), (_) => false);
  }
}

class Configuracoes extends StatelessWidget {
  const Configuracoes({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Configurações')),
      body: ListView(padding: EdgeInsets.all(20), children: [
        Text('Aparência',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.instance,
            builder: (_, value, __) => DropdownButtonFormField<ThemeMode>(
                value: value,
                decoration: InputDecoration(labelText: 'Tema'),
                items: [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('Seguir o sistema')),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Claro')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro'))
                ],
                onChanged: (mode) {
                  if (mode != null) AppSettings.instance.change(mode);
                })),
        SizedBox(height: 24),
        ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Horário brasileiro'),
            subtitle: Text('Português do Brasil • formato de 24 horas')),
        ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Limpar dados temporários'),
            onTap: () async {
              await LocalStore.instance.clear(SessionService.instance.escopo);
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dados temporários removidos.')));
            }),
        ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sair da conta'),
            onTap: () => sairDaConta(context)),
      ]));
}

class MinhaConta extends StatefulWidget {
  const MinhaConta({super.key});
  @override
  State<MinhaConta> createState() => _MinhaContaState();
}

class _MinhaContaState extends State<MinhaConta> {
  final nome = TextEditingController(),
      email = TextEditingController(),
      telefone = TextEditingController(),
      senha = TextEditingController();
  bool carregando = true, salvando = false;
  String? erro;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiService().obterPerfilUsuario();
      if (!mounted) return;
      nome.text = p?['name'] ?? '';
      email.text = p?['email'] ?? '';
      telefone.text = p?['phoneNumber'] ?? '';
    } catch (e) {
      erro =
          e is ApiException ? e.message : 'Não foi possível carregar a conta.';
    }
    if (mounted) setState(() => carregando = false);
  }

  Future<void> _save() async {
    setState(() => salvando = true);
    try {
      final p = await ApiService().requisicao('PATCH', '/minha-conta', dados: {
        'nome': nome.text,
        'email': email.text,
        'telefone': telefone.text,
        if (senha.text.isNotEmpty) 'senha': senha.text
      });
      SessionService.instance.nomeUsuario = p['name'];
      senha.clear();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Conta atualizada.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Falha ao atualizar a conta.')));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    telefone.dispose();
    senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Minha conta')),
      body: carregando
          ? Center(child: CircularProgressIndicator())
          : erro != null
              ? Center(child: Text(erro!))
              : ListView(padding: EdgeInsets.all(20), children: [
                  Text('Perfil: ${SessionService.instance.tipoUsuario}',
                      style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 20),
                  TextField(
                      controller: nome,
                      decoration: InputDecoration(labelText: 'Nome')),
                  SizedBox(height: 16),
                  TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: 'E-mail')),
                  SizedBox(height: 16),
                  TextField(
                      controller: telefone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [TelefoneInputFormatter()],
                      decoration: InputDecoration(labelText: 'Telefone')),
                  SizedBox(height: 16),
                  TextField(
                      controller: senha,
                      obscureText: true,
                      decoration:
                          InputDecoration(labelText: 'Nova senha (opcional)')),
                  SizedBox(height: 24),
                  FilledButton(
                      onPressed: salvando ? null : _save,
                      child:
                          Text(salvando ? 'Salvando...' : 'Salvar alterações')),
                ]));
}
