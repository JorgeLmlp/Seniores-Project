import 'package:flutter/material.dart';

/// Textos informativos temporários. Substituir pelo documento jurídico aprovado
/// antes da publicação do Seniores ou coleta de dados reais.
class DocumentoLegal extends StatelessWidget {
  const DocumentoLegal({super.key, required this.privacidade});

  final bool privacidade;

  @override
  Widget build(BuildContext context) {
    final titulo = privacidade ? 'Política de Privacidade' : 'Termos de Uso';
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Text('DOCUMENTO PRELIMINAR — A equipe responsável deve '
                'substituir este conteúdo pela versão jurídica aprovada antes da publicação. '
                'Não representa uma política definitiva.'))),
          const SizedBox(height: 18),
          if (privacidade) ...[
            const Text('O Seniores registra dados de conta e informações de cuidados '
                'informadas por usuários autorizados, como medicamentos, consultas '
                'e registros de saúde. Esses dados podem ser sensíveis.'),
            const SizedBox(height: 12),
            const Text('Antes de publicar, a equipe precisa informar: responsável '
                'pelo tratamento, finalidades, bases legais, compartilhamentos, '
                'prazo de retenção, medidas de segurança e contato para os '
                'direitos previstos na LGPD.'),
          ] else ...[
            const Text('O Seniores é uma ferramenta de organização de cuidados. '
                'Não substitui avaliação profissional ou atendimento de emergência.'),
            const SizedBox(height: 12),
            const Text('Antes de publicar, a equipe precisa definir regras de '
                'acesso, deveres dos usuários, uso adequado de informações de '
                'terceiros, responsabilidades e canal de suporte.'),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar ao cadastro')),
        ]),
      )),
    );
  }
}
