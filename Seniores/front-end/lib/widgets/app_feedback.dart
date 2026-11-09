import 'package:flutter/material.dart';

enum TipoFeedback { sucesso, erro, aviso }

void mostrarFeedback(
  BuildContext context, {
  required String mensagem,
  required TipoFeedback tipo,
  String? titulo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;
  final (cor, icone, tituloPadrao) = switch (tipo) {
    TipoFeedback.sucesso => (
        const Color(0xFF198754),
        Icons.check_circle_rounded,
        'Tudo certo!',
      ),
    TipoFeedback.erro => (scheme.error, Icons.error_rounded, 'Algo deu errado'),
    TipoFeedback.aviso => (
        const Color(0xFFB7791F),
        Icons.info_rounded,
        'Atenção',
      ),
  };
  final fundo = Color.alphaBlend(
    cor.withValues(alpha: 0.10),
    scheme.surface,
  );

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: fundo,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        padding: EdgeInsets.zero,
        duration: Duration(seconds: tipo == TipoFeedback.erro ? 5 : 4),
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cor.withValues(alpha: 0.35)),
        ),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: cor, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo ?? tituloPadrao,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mensagem,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar aviso',
                visualDensity: VisualDensity.compact,
                onPressed: messenger.hideCurrentSnackBar,
                icon: Icon(
                  Icons.close_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class AvisoInline extends StatelessWidget {
  const AvisoInline({
    super.key,
    required this.mensagem,
    this.tipo = TipoFeedback.erro,
  });

  final String mensagem;
  final TipoFeedback tipo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = switch (tipo) {
      TipoFeedback.sucesso => const Color(0xFF198754),
      TipoFeedback.erro => scheme.error,
      TipoFeedback.aviso => const Color(0xFFB7791F),
    };
    final icone = switch (tipo) {
      TipoFeedback.sucesso => Icons.check_circle_outline_rounded,
      TipoFeedback.erro => Icons.error_outline_rounded,
      TipoFeedback.aviso => Icons.info_outline_rounded,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withValues(alpha: 0.09), scheme.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
