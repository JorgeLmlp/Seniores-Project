import 'package:flutter/material.dart';
import 'package:widgets/pages/registro%20diario/tela_registroDiario.dart';
import '../pages/tela_inicio.dart';
import '../pages/medicamentos/tela_medicamentos.dart';
import '../pages/cuidados/tela_cuidados.dart';
import '../utils/cores.dart';
import '../pages/tela_notificacoes.dart';

class Menu extends StatelessWidget {
  final int paginaAtual;

  const Menu({
    super.key,
    required this.paginaAtual,
  });

  void _navegar(BuildContext context, int index) {
    if (index == paginaAtual) return;

    Widget proximaTela;

    switch (index) {
      case 0:
        proximaTela = const Home();

        break;

      case 1:
        proximaTela = const Medicamentos();

        break;

      case 2:
        proximaTela = const Cuidados();

        break;

      case 3:
        proximaTela = const RegistroDiario();

        break;

      case 4:
        proximaTela = const Notificacoes();

        break;

      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => proximaTela),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: paginaAtual,
      onTap: (index) => _navegar(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Cores.azul,
      unselectedItemColor: Cores.cinza,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 22),
          label: "Início",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication, size: 22),
          label: "Medicamentos",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.health_and_safety, size: 22),
          label: "Cuidados",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today, size: 22),
          label: "Diário",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications, size: 22),
          label: "Notificações",
        ),
      ],
    );
  }
}
