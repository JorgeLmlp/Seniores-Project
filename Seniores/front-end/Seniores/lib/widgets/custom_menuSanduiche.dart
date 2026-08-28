import 'package:flutter/material.dart';
import 'package:widgets/pages/cuidados/tela_cuidados.dart';
import '../pages/medicamentos/tela_medicamentos.dart';
import '../pages/registro diario/tela_relatorio.dart';
import '../pages/cuidadores/tela_cuidadores.dart';
import '../pages/comunicados/tela_comunicados.dart';
import '../utils/cores.dart';

class MenuSanduiche extends StatelessWidget {
  const MenuSanduiche({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            _buildSectionHeader("Cuidados"),

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
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Relatorio(),
                  ),
                );
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
              onTap: () {},
            ),
            // _buildMenuItem(
            //   icon: Icons.description,
            //   title: "Relatórios",
            //   onTap: () {},
            // ),
            // const SizedBox(height: 20),
            // _buildSectionHeader("Apoio"),
            // _buildMenuItem(
            //   icon: Icons.menu_book,
            //   title: "Dicionário",
            //   onTap: () {},
            // ),
            // _buildMenuItem(
            //   icon: Icons.help_outline,
            //   title: "Ajuda",
            //   onTap: () {},
            // ),
            // const SizedBox(height: 20),
            // _buildSectionHeader("Configurações"),
            // _buildMenuItem(
            //   icon: Icons.settings,
            //   title: "Configurações",
            //   onTap: () {},
            // ),
            // _buildMenuItem(
            //   icon: Icons.account_circle,
            //   title: "Minha conta",
            //   onTap: () {},
            // ),
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
