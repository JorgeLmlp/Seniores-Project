import 'package:flutter/material.dart';
import '../pages/tela_inicio.dart';
import '../pages/tela_medicamentos.dart';
// import '../pages/tela_cuidados.dart';
// import '../pages/tela_diarioSaude.dart';
// import '../pages/tela_notificacoes.dart';

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
        //proximaTela = const Cuidados();

        return;

      case 3:
        //proximaTela = const DiarioSaude();

        return;

      case 4:
        //proximaTela = const Notificacoes();

        return;

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
    // Retornando diretamente o BottomNavigationBar sem SizedBox fixo
    return BottomNavigationBar(
      currentIndex: paginaAtual,
      onTap: (index) => _navegar(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF275DAD),
      unselectedItemColor: const Color(0xFF636E72),
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