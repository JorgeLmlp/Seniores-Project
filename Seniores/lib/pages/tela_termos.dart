import 'package:flutter/material.dart';

class TelaTermos extends StatelessWidget {
  const TelaTermos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          'Termos de Uso\n\n'
          'Leia as condições de utilização do Seniores antes de criar sua conta. '
          'O aplicativo organiza informações de cuidado e não substitui avaliação '
          'ou orientação de profissionais de saúde.\n\n'
          'Ao utilizar o aplicativo, você se compromete a informar dados verdadeiros '
          'e a proteger suas credenciais de acesso.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
