import 'package:flutter/material.dart';
import '../../utils/cores.dart';
import 'dados_documentos_legais.dart';

class DocumentoLegal extends StatelessWidget {
  const DocumentoLegal({super.key, required this.tipo});

  final TipoDocumentoLegal tipo;

  @override
  Widget build(BuildContext context) {
    final bool ehConsentimento = tipo == TipoDocumentoLegal.consentimento;
    final titulo = ehConsentimento ? 'Termo de Consentimento' : 'Termos de Uso';
    final blocos = ehConsentimento
        ? blocosTermoConsentimento
        : blocosTermosDeUso;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                itemCount: blocos.length + 3,
                itemBuilder: (context, indice) {
                  if (indice == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        titulo,
                        style: tema.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Cores.azul,
                        ),
                      ),
                    );
                  }
                  if (indice == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Cores.azul),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Minuta adaptada do modelo LGPD enviado pela equipe. '
                                  'Identificação do responsável, contato de privacidade, '
                                  'medidas de segurança e versão final precisam ser '
                                  'revisados e aprovados antes da publicação.',
                                  style: tema.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (indice == blocos.length + 2) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar ao cadastro'),
                      ),
                    );
                  }

                  final bloco = blocos[indice - 2];
                  if (bloco.titulo) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
                      child: Text(
                        bloco.texto,
                        style: tema.textTheme.titleMedium?.copyWith(
                          color: Cores.azul,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  if (bloco.item) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(bloco.texto)),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(bloco.texto, style: tema.textTheme.bodyMedium),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
