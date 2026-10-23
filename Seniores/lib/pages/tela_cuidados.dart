import 'package:flutter/material.dart';
import '../widgets/custom_menu.dart';
import 'tela_sinais_vitais.dart';
import 'tela_consultas_exames.dart';
import 'tela_incidentes.dart';
import 'tela_higiene.dart';
import 'tela_lesoes.dart';
import 'tela_dietas.dart';

class Cuidados extends StatelessWidget {
  const Cuidados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuidados')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: const Text('Sinais vitais'),
            subtitle: const Text('Registrar e consultar medições'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SinaisVitais()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.event_note),
            title: Text('Consultas e exames'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsultasExames()),
            ),
            subtitle: Text('Agenda, resultados e documentos'),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('Incidentes'),
            subtitle: const Text('Registrar e acompanhar ocorrências'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Incidentes()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Checklist de higiene'),
            subtitle: const Text('Registrar e acompanhar rotinas de higiene'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HigienePage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.healing_outlined),
            title: const Text('Prontuário de lesões'),
            subtitle: const Text('Acompanhar descrição, fotos e evolução'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Lesoes()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Dietas e restrições'),
            subtitle: const Text('Gerenciar planos alimentares'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Dietas()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Menu(paginaAtual: 2),
    );
  }
}
