import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_menuSanduiche.dart';
import 'tela_inicio.dart';
import 'tela_permissoes.dart';

class Vinculos extends StatefulWidget {
  const Vinculos({super.key});
  @override
  State<Vinculos> createState() => _VinculosState();
}

class _VinculosState extends State<Vinculos> {
  final api = ApiService();
  List<dynamic> pacientes = [], solicitacoes = [];
  bool ocupado = false;
  String? erro;
  bool get responsavel => SessionService.instance.tipoUsuario == 'responsavel';
  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      final p = await api.requisicao('GET', '/minha-conta/pacientes') as List;
      final s =
          await api.requisicao('GET', '/minha-conta/solicitacoes') as List;
      if (mounted) {
        setState(() {
          pacientes = p;
          solicitacoes = s;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro =
            e is ApiException ? e.message : 'Falha ao carregar vínculos.');
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> enviar(String rota, Map<String, dynamic> dados,
      {String metodo = 'POST'}) async {
    setState(() => ocupado = true);
    try {
      await api.requisicao(metodo, rota, dados: dados);
      await carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                e is ApiException ? e.message : 'Não foi possível salvar.')));
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> pedirCpfPaciente() async {
    var valor = '';
    final cpf = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Vincular paciente'),
                content: TextField(
                    onChanged: (texto) => valor = texto,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    decoration: InputDecoration(
                        labelText: 'CPF do paciente',
                        helperText:
                            'A pessoa precisa ter uma conta cadastrada.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, valor),
                      child: Text('Enviar'))
                ]));
    if (cpf == null || !mounted) return;
    if (cpf.replaceAll(RegExp(r'\D'), '').length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Informe os 11 dígitos do CPF.')));
      return;
    }
    await enviar('/minha-conta/pacientes', {'cpf': cpf});
  }

  Future<void> convidarCuidador(int pacienteId) async {
    var valor = '';
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar cuidador'),
        content: TextField(
          onChanged: (texto) => valor = texto,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail do cuidador',
            hintText: 'cuidador@exemplo.com',
            helperText: 'Use o e-mail cadastrado na conta do cuidador.',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, valor),
              child: const Text('Enviar convite')),
        ],
      ),
    );
    if (email == null || !mounted) return;
    final normalizado = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizado)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um e-mail válido.')));
      return;
    }
    await enviar('/minha-conta/solicitacoes',
        {'email': normalizado, 'paciente_id': pacienteId});
  }

  void abrirPaciente(Map paciente) {
    SessionService.instance.pacienteSelecionado = paciente['id'] as int;
    SessionService.instance.nomePaciente = paciente['name'] as String?;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const Home()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(responsavel ? 'Pacientes e convites' : 'Meus pacientes'),
          actions: [
            IconButton(
                onPressed: ocupado ? null : carregar, icon: Icon(Icons.refresh))
          ]),
      drawer: MenuSanduiche(),
      body: ocupado
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView(padding: EdgeInsets.all(20), children: [
                Center(
                    child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF245A9F), Color(0xFF397BC8)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              responsavel
                                  ? Icons.family_restroom
                                  : Icons.volunteer_activism_outlined,
                              color: Colors.white,
                              size: 36),
                          const SizedBox(height: 14),
                          Text(
                              responsavel
                                  ? 'Cuidado em conjunto'
                                  : 'Escolha quem cuidar agora',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              responsavel
                                  ? 'Vincule seus pacientes e envie convites aos cuidadores pelo e-mail cadastrado.'
                                  : 'Selecione um paciente para acessar os cuidados e acompanhe seus convites.',
                              style: const TextStyle(
                                  color: Colors.white, height: 1.4)),
                        ]),
                  ),
                )),
                const SizedBox(height: 20),
                if (erro != null)
                  Text(erro!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                Text(responsavel ? 'Pacientes vinculados' : 'Seus pacientes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                if (pacientes.isEmpty)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                              'Nenhum paciente vinculado. Os vínculos são iniciados pelo responsável.'))),
                ...pacientes.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color:
                                Theme.of(context).colorScheme.outlineVariant)),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          ListTile(
                              leading: CircleAvatar(
                                  child: Icon(Icons.person_outline)),
                              title: Text('${p['name']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(SessionService
                                          .instance.pacienteSelecionado ==
                                      p['id']
                                  ? responsavel
                                      ? 'Paciente em atendimento'
                                      : p['pode_escrever'] == true
                                          ? 'Em atendimento · pode registrar'
                                          : 'Em atendimento · somente leitura'
                                  : responsavel
                                      ? 'Toque para acessar os cuidados'
                                      : p['pode_escrever'] == true
                                          ? 'Pode registrar informações'
                                          : 'Somente leitura'),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () => abrirPaciente(p)),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                  onPressed: () => abrirPaciente(p),
                                  icon: const Icon(Icons.arrow_forward),
                                  label: Text(responsavel
                                      ? 'Abrir cuidados'
                                      : SessionService.instance
                                                  .pacienteSelecionado ==
                                              p['id']
                                          ? 'Continuar atendimento'
                                          : 'Selecionar paciente'))),
                          if (responsavel && p['cuidador_id'] != null)
                            const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Chip(label: Text('Cuidador vinculado'))),
                          if (responsavel && p['cuidador_id'] == null)
                            TextButton.icon(
                                onPressed: () =>
                                    convidarCuidador(p['id'] as int),
                                icon: Icon(Icons.outgoing_mail),
                                label: Text('Convidar cuidador por e-mail')),
                          if (responsavel)
                            TextButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PermissoesPaciente(
                                            pacienteId: p['id'] as int,
                                            pacienteNome: '${p['name']}',
                                            cuidadorId:
                                                p['cuidador_id'] as int?))),
                                icon: const Icon(
                                    Icons.admin_panel_settings_outlined),
                                label: const Text(
                                    'Gerenciar permissões de escrita'))
                        ])))),
                if (responsavel)
                  FilledButton.icon(
                      onPressed: pedirCpfPaciente,
                      icon: Icon(Icons.add),
                      label: Text('Vincular paciente')),
                SizedBox(height: 28),
                Text(
                    responsavel
                        ? 'Convites enviados'
                        : 'Solicitações recebidas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (solicitacoes.isEmpty)
                  Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nenhuma solicitação.')),
                ...solicitacoes.map((s) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color:
                                Theme.of(context).colorScheme.outlineVariant)),
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.mark_email_unread_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        'Paciente: ${s['paciente']?['nome'] ?? 'Indisponível'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold))),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                  'Responsável: ${s['responsavel']?['nome'] ?? 'Indisponível'}'),
                              if (responsavel)
                                Text(
                                    'Cuidador: ${s['cuidador']?['nome'] ?? 'Indisponível'}'),
                              const SizedBox(height: 8),
                              Chip(label: Text('Status: ${s['status']}')),
                              if (!responsavel && s['status'] == 'pendente')
                                Wrap(spacing: 12, children: [
                                  FilledButton(
                                      onPressed: () => enviar(
                                          '/minha-conta/solicitacoes/${s['id']}',
                                          {'status': 'aceita'},
                                          metodo: 'PATCH'),
                                      child: Text('Aceitar')),
                                  OutlinedButton(
                                      onPressed: () => enviar(
                                          '/minha-conta/solicitacoes/${s['id']}',
                                          {'status': 'recusada'},
                                          metodo: 'PATCH'),
                                      child: Text('Recusar')),
                                ]),
                            ])))),
              ])));
}
