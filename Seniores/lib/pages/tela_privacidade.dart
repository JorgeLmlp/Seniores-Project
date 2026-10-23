import 'package:flutter/material.dart';

class TelaPrivacidade extends StatelessWidget {
  const TelaPrivacidade({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          'Política de Privacidade\n\n'
          'Os dados informados no Seniores são utilizados para organizar o cuidado '
          'do paciente e são enviados à API configurada pelo sistema.\n\n'
          'Não compartilhe sua senha. Solicite a exclusão da conta quando não quiser '
          'mais utilizar o serviço.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
