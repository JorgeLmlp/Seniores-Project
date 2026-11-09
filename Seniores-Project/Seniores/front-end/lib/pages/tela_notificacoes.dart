import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'tela_vinculos.dart';

class Notificacoes extends StatefulWidget {
  const Notificacoes({super.key});

  @override
  State<Notificacoes> createState() => _NotificacoesState();
}

class _NotificacoesState extends State<Notificacoes> {
  final api = ApiService();
  List<dynamic> convites = [], alertas = [];
  bool carregando = true, respondendo = false;
  String? erro;

  bool get cuidador => SessionService.instance.tipoUsuario == 'cuidador';
  bool get pacienteAtivo =>
      SessionService.instance.tipoUsuario == 'paciente' ||
      SessionService.instance.pacienteSelecionado != null;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      final novosConvites = cuidador
          ? await api.requisicao('GET', '/minha-conta/solicitacoes') as List
          : <dynamic>[];
      if (mounted) setState(() => convites = novosConvites);
      final novosAlertas = pacienteAtivo
          ? await api.requisicao('GET',
                  '/pacientes/${SessionService.instance.pacienteId}/alertas-estoque')
              as List
          : <dynamic>[];
      if (mounted) {
        setState(() {
          convites = novosConvites;
          alertas = novosAlertas;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = e is ApiException
            ? e.message
            : 'Não foi possível carregar as notificações.');
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> responder(int id, String status) async {
    setState(() => respondendo = true);
    try {
      await api.requisicao('PATCH', '/minha-conta/solicitacoes/$id',
          dados: {'status': status});
      await carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(status == 'aceita'
                ? 'Convite aceito. O paciente está disponível em Meus pacientes.'
                : 'Convite recusado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ApiException
                ? e.message
                : 'Não foi possível responder ao convite.')));
      }
    } finally {
      if (mounted) setState(() => respondendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pendentes = convites.where((c) => c['status'] == 'pendente').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações'), actions: [
        IconButton(
            tooltip: 'Atualizar',
            onPressed: carregando ? null : carregar,
            icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: carregar,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (carregando) const LinearProgressIndicator(),
              if (erro != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(erro!,
                        style: TextStyle(color: tema.colorScheme.error))),
              if (cuidador) ...[
                Text('Convites para cuidar',
                    style: tema.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Responda aos convites enviados pelos responsáveis.',
                    style: TextStyle(color: tema.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                if (pendentes.isEmpty && !carregando)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nenhum convite pendente.'))),
                ...pendentes.map(
                  (convite) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: tema.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  CircleAvatar(
                                      child: Icon(Icons.person_add_alt_1)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            '${convite['paciente']?['nome'] ?? 'Paciente'}',
                                            style: tema.textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                        Text(
                                            'Convite de ${convite['responsavel']?['nome'] ?? 'responsável'}'),
                                      ])),
                                ]),
                                const SizedBox(height: 16),
                                Wrap(spacing: 10, runSpacing: 8, children: [
                                  FilledButton.icon(
                                      onPressed: respondendo
                                          ? null
                                          : () => responder(
                                              convite['id'] as int, 'aceita'),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Aceitar')),
                                  OutlinedButton(
                                      onPressed: respondendo
                                          ? null
                                          : () => responder(
                                              convite['id'] as int, 'recusada'),
                                      child: const Text('Recusar')),
                                ]),
                              ]))),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Vinculos())),
                  icon: const Icon(Icons.switch_account_outlined),
                  label: const Text('Ver ou trocar paciente'),
                ),
                const SizedBox(height: 24),
              ],
              if (pacienteAtivo) ...[
                Text('Alertas do paciente',
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (alertas.isEmpty && !carregando)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nenhum alerta no momento.'))),
                ...alertas.map((alerta) => Card(
                    child: ListTile(
                        leading:
                            const Icon(Icons.notifications_active_outlined),
                        title: Text('${alerta['titulo'] ?? 'Alerta'}'),
                        subtitle: Text('${alerta['mensagem'] ?? ''}')))),
              ],
            ]),
          )),
        ]),
      ),
    );
  }
}
