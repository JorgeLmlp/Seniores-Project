import '../pages/tela_vinculos.dart';
import '../pages/tela_conta.dart';
import '../pages/tela_pdf.dart';
import '../services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:widgets/pages/cuidados/tela_cuidados.dart';
import '../models/registroDiario.dart';
import '../services/api_service.dart';
import '../pages/medicamentos/tela_medicamentos.dart';
import '../pages/registro diario/tela_relatorio.dart';
import '../pages/cuidadores/tela_cuidadores.dart';
import '../pages/comunicados/tela_comunicados.dart';
import '../pages/gastos/tela_gastos.dart';
import '../pages/dicionario/tela_dicionario.dart';
import '../pages/ajuda/tela_ajuda.dart';
import '../utils/cores.dart';
import '../models/recurso_cuidado.dart';
import '../pages/cuidados/tela_registros_cuidado.dart';

class MenuSanduiche extends StatelessWidget {
  const MenuSanduiche({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;
    if (session.tipoUsuario != 'paciente' &&
        session.pacienteSelecionado == null) {
      return Drawer(
          child: SafeArea(
              child: ListView(children: [
        const ListTile(
            title: Text('Selecione um paciente para acessar os cuidados.')),
        ListTile(
            title: const Text('Pacientes e vínculos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Vinculos()));
            }),
        ListTile(
            title: const Text('Minha conta'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MinhaConta()));
            }),
        ListTile(
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Configuracoes()));
            }),
        ListTile(
            title: const Text('Sair da conta'),
            onTap: () => sairDaConta(context)),
      ])));
    }
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            if (SessionService.instance.tipoUsuario != 'paciente')
              _buildMenuItem(
                  icon: Icons.switch_account_outlined,
                  title: 'Trocar paciente / vínculos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Vinculos()));
                  }),
            _buildMenuItem(
                icon: Icons.logout,
                title: 'Sair da conta',
                onTap: () => sairDaConta(context)),
            _buildSectionHeader("Cuidados"),
            for (final recurso in recursosCuidado)
              _buildMenuItem(icon: recurso.icone, title: recurso.titulo,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      RegistrosCuidado(recurso: recurso)));
                }),
            _buildMenuItem(
              icon: Icons.medication,
              title: "Medicamentos",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Medicamentos()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.health_and_safety,
              title: "Exames e consultas",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Cuidados()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.calendar_today,
              title: "Diário de saúde",
              onTap: () async {
                Navigator.pop(context);

                try {
                  final apiService = ApiService();
                  final registros = await apiService.listarDiarios();

                  if (context.mounted) {
                    Registro? ultimoRegistro;
                    if (registros.isNotEmpty) {
                      ultimoRegistro = Registro.fromApiJson(registros.first);
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Relatorio(registro: ultimoRegistro),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Relatorio(),
                      ),
                    );
                  }
                }
              },
            ),
            _buildMenuItem(
                icon: Icons.people,
                title: "Cuidadores",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Cuidadores(),
                    ),
                  );
                }),
            const SizedBox(height: 20),
            _buildSectionHeader("Controle"),
            _buildMenuItem(
              icon: Icons.campaign,
              title: "Comunicados",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Destinatarios(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.attach_money,
              title: "Gastos",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Gastos(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.description,
              title: "Relatórios",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RelatoriosPdf()));
              },
            ),
            const SizedBox(height: 20),
            _buildSectionHeader("Apoio"),
            _buildMenuItem(
              icon: Icons.menu_book,
              title: "Dicionário",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Dicionario(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: "Ajuda",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Ajuda(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildSectionHeader("Configurações"),
            _buildMenuItem(
              icon: Icons.settings,
              title: "Configurações",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Configuracoes()));
              },
            ),
            _buildMenuItem(
              icon: Icons.account_circle,
              title: "Minha conta",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MinhaConta()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Cores.azul,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Cores.azul),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
