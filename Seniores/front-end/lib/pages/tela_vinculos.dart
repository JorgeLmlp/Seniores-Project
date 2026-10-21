import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_menuSanduiche.dart';
import 'tela_inicio.dart';

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
      if (mounted)
        setState(() {
          pacientes = p;
          solicitacoes = s;
        });
    } catch (e) {
      if (mounted)
        setState(() => erro =
            e is ApiException ? e.message : 'Falha ao carregar vínculos.');
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                e is ApiException ? e.message : 'Não foi possível salvar.')));
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> pedirCpf({int? pacienteId}) async {
    final controller = TextEditingController();
    final cpf = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(pacienteId == null
                    ? 'Vincular paciente'
                    : 'Convidar cuidador'),
                content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    decoration: InputDecoration(
                        labelText: 'CPF',
                        helperText:
                            'A pessoa precisa ter uma conta cadastrada.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: Text('Enviar'))
                ]));
    controller.dispose();
    if (cpf == null || !mounted) return;
    if (cpf.replaceAll(RegExp(r'\D'), '').length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Informe os 11 dígitos do CPF.')));
      return;
    }
    await enviar(
        pacienteId == null
            ? '/minha-conta/pacientes'
            : '/minha-conta/solicitacoes',
        {'cpf': cpf, if (pacienteId != null) 'paciente_id': pacienteId});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(responsavel ? 'Pacientes e vínculos' : 'Meus pacientes'),
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
                if (erro != null)
                  Text(erro!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                Text(
                    responsavel
                        ? 'Seus pacientes'
                        : 'Selecione o paciente que está atendendo',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 12),
                if (pacientes.isEmpty)
                  Text(
                      'Nenhum paciente vinculado. Os vínculos são iniciados pelo responsável.'),
                ...pacientes.map((p) => Card(
                        child: Column(children: [
                      ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text(p['name']),
                          subtitle: Text('Toque para acessar os cuidados'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            SessionService.instance.pacienteSelecionado =
                                p['id'];
                            SessionService.instance.nomePaciente = p['name'];
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => Home()),
                                (_) => false);
                          }),
                      if (responsavel)
                        TextButton.icon(
                            onPressed: () => pedirCpf(pacienteId: p['id']),
                            icon: Icon(Icons.person_add_alt),
                            label: Text('Convidar cuidador por CPF'))
                    ]))),
                if (responsavel)
                  FilledButton.icon(
                      onPressed: () => pedirCpf(),
                      icon: Icon(Icons.add),
                      label: Text('Vincular paciente por CPF')),
                SizedBox(height: 28),
                Text('Solicitações',
                    style: Theme.of(context).textTheme.titleLarge),
                if (solicitacoes.isEmpty)
                  Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nenhuma solicitação.')),
                ...solicitacoes.map((s) => Card(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Paciente: ${s['paciente']?['nome'] ?? 'Indisponível'}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                  'Responsável: ${s['responsavel']?['nome'] ?? 'Indisponível'}'),
                              Text(
                                  'Telefone: ${s['responsavel']?['telefone'] ?? ''}'),
                              Text(
                                  'Cuidador: ${s['cuidador']?['nome'] ?? 'Indisponível'}'),
                              Text('Status: ${s['status']}'),
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
