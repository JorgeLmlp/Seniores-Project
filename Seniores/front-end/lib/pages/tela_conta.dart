import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/local_store.dart';
import '../services/app_settings.dart';
import '../utils/mascaras.dart';

Future<void> sairDaConta() async {
  final scope = SessionService.instance.escopo;
  try {
    await LocalStore.instance.clear(scope);
  } finally {
    await SessionService.instance.encerrar();
  }
}

class Configuracoes extends StatelessWidget {
  const Configuracoes({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Configurações')),
        body: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Text(
              'Aparência',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppSettings.instance,
              builder: (_, value, __) => DropdownButtonFormField<ThemeMode>(
                initialValue: value,
                decoration: InputDecoration(labelText: 'Tema'),
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Seguir o sistema'),
                  ),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Claro')),
                  DropdownMenuItem(
                      value: ThemeMode.dark, child: Text('Escuro')),
                ],
                onChanged: (mode) {
                  if (mode != null) AppSettings.instance.change(mode);
                },
              ),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Horário brasileiro'),
              subtitle: Text('Português do Brasil • formato de 24 horas'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Limpar dados temporários'),
              onTap: () async {
                await LocalStore.instance.clear(SessionService.instance.escopo);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dados temporários removidos.')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair da conta'),
              onTap: sairDaConta,
            ),
          ],
        ),
      );
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
  final cpf = TextEditingController(), idade = TextEditingController(),
      preferencias = TextEditingController();
  String? tipoSanguineo;
  Map<String, dynamic> preferenciasSalvas = {};
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
      cpf.text = p?['cpf'] ?? '';
      idade.text = '${p?['idade'] ?? ''}';
      tipoSanguineo = p?['tipo_sanguineo'] as String?;
      if (p?['preferencias'] is Map) {
        preferenciasSalvas = Map<String, dynamic>.from(p!['preferencias'] as Map);
      }
      preferencias.text = '${preferenciasSalvas['observacoes'] ?? ''}';
    } catch (e) {
      erro =
          e is ApiException ? e.message : 'Não foi possível carregar a conta.';
    }
    if (mounted) setState(() => carregando = false);
  }

  Future<void> _save() async {
    final ePaciente = SessionService.instance.tipoUsuario == 'paciente';
    final idadeNumero = int.tryParse(idade.text.trim());
    if (ePaciente && idade.text.trim().isNotEmpty &&
        (idadeNumero == null || idadeNumero < 0 || idadeNumero > 130)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Idade deve estar entre 0 e 130 anos.')));
      return;
    }
    setState(() => salvando = true);
    try {
      final p = await ApiService().requisicao(
        'PATCH',
        '/minha-conta',
        dados: {
          'nome': nome.text,
          'email': email.text,
          'telefone': telefone.text,
          'cpf': cpf.text,
          if (ePaciente) 'idade': idadeNumero,
          if (ePaciente && tipoSanguineo != null) 'tipo_sanguineo': tipoSanguineo,
          if (ePaciente) 'preferencias': {
            ...preferenciasSalvas,
            'observacoes': preferencias.text.trim(),
          },
          if (senha.text.isNotEmpty) 'senha': senha.text,
        },
      );
      await SessionService.instance.atualizarNome(p['name']);
      senha.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Conta atualizada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Falha ao atualizar a conta.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Future<void> _excluirConta() async {
    final senhaConfirmacao = TextEditingController();
    try {
      final confirmado = await showDialog<String>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir minha conta'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('A exclusão é definitiva. Se houver vínculos ou dados de pacientes, '
              'a API vai bloquear a operação até sua resolução.'),
            const SizedBox(height: 12),
            TextField(controller: senhaConfirmacao, obscureText: true,
              decoration: const InputDecoration(labelText: 'Digite sua senha para confirmar')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, senhaConfirmacao.text),
              child: const Text('Excluir permanentemente')),
          ],
        ));
      if (confirmado == null || confirmado.isEmpty) return;
      await ApiService().requisicao('DELETE', '/minha-conta', dados: {'senha': confirmado});
      await sairDaConta();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Não foi possível excluir a conta.')));
      }
    } finally {
      senhaConfirmacao.dispose();
    }
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    telefone.dispose();
    senha.dispose();
    cpf.dispose();
    idade.dispose();
    preferencias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Minha conta')),
        body: carregando
            ? Center(child: CircularProgressIndicator())
            : erro != null
                ? Center(child: Text(erro!))
                : ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      Text(
                        'Perfil: ${SessionService.instance.tipoUsuario}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: nome,
                        decoration: InputDecoration(labelText: 'Nome'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: 'E-mail'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: telefone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [TelefoneInputFormatter()],
                        decoration: InputDecoration(labelText: 'Telefone'),
                      ),
                      SizedBox(height: 16),
                      TextField(controller: cpf, decoration:
                          InputDecoration(labelText: 'CPF')),
                      if (SessionService.instance.tipoUsuario == 'paciente') ...[
                        SizedBox(height: 16),
                        TextField(controller: idade, keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Idade')),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(initialValue: tipoSanguineo,
                            decoration: InputDecoration(labelText: 'Tipo sanguíneo'),
                            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                            onChanged: (valor) => setState(() => tipoSanguineo = valor)),
                        SizedBox(height: 16),
                        TextField(controller: preferencias, maxLines: 2,
                            decoration: InputDecoration(labelText: 'Preferências / observações')),
                      ],
                      SizedBox(height: 16),
                      TextField(
                        controller: senha,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: 'Nova senha (opcional)'),
                      ),
                      SizedBox(height: 24),
                      FilledButton(
                        onPressed: salvando ? null : _save,
                        child: Text(
                            salvando ? 'Salvando...' : 'Salvar alterações'),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(onPressed: salvando ? null : _excluirConta,
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: const Text('Excluir minha conta')),
                    ],
                  ),
      );
}
