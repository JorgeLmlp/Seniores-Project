import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'tela_vinculos.dart';

class Notificacoes extends StatelessWidget {
  const Notificacoes({super.key});
  @override
  Widget build(BuildContext context) {
    if (SessionService.instance.tipoUsuario != 'paciente')
      return const Vinculos();
    return Scaffold(
        appBar: AppBar(title: const Text('Notificações')),
        body: FutureBuilder<dynamic>(
            future: ApiService().requisicao('GET',
                '/pacientes/${SessionService.instance.pacienteId}/alertas-estoque'),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snap.hasError)
                return const Center(
                    child: Text('Não foi possível carregar as notificações.'));
              final itens = snap.data as List;
              if (itens.isEmpty)
                return const Center(
                    child: Text('Nenhuma notificação no momento.'));
              return ListView(
                  children: itens
                      .map((n) => ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(n['titulo']),
                          subtitle: Text(n['mensagem'])))
                      .toList());
            }));
  }
}
