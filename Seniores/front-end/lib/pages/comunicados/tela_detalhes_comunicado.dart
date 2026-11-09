import 'package:flutter/material.dart';
import '../../widgets/custom_textos.dart';
import '../../widgets/custom_botao.dart';
import '../../models/destinatario.dart';
import '../../utils/cores.dart';

class DetalhesComunicado extends StatelessWidget {
  final Destinatario destinatario;
  final String mensagem;

  const DetalhesComunicado({
    super.key,
    required this.destinatario,
    required this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  AppText(
                      texto: 'Detalhes do Comunicado',
                      estilo: AppText.titulo,
                      tamanho: 22),
                ],
              ),
              SizedBox(height: 32),
              AppText(
                  texto: 'Destinatário',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Cores.cinza.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      texto: destinatario.nome,
                      estilo: AppText.corpo,
                      peso: FontWeight.bold,
                      tamanho: 16,
                      cor: Cores.azul,
                    ),
                    SizedBox(height: 4),
                    AppText(
                      texto: 'Vínculo: ${destinatario.vinculo}',
                      estilo: AppText.corpo,
                      tamanho: 14,
                      cor: Cores.cinza,
                    ),
                    SizedBox(height: 2),
                    AppText(
                      texto: 'WhatsApp: ${destinatario.telefone}',
                      estilo: AppText.corpo,
                      tamanho: 14,
                      cor: Cores.cinza,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              AppText(
                  texto: 'Mensagem Enviada',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Cores.cinza.withValues(alpha: 0.3)),
                ),
                child: AppText(
                  texto: mensagem.isEmpty
                      ? 'Nenhuma mensagem informada.'
                      : mensagem,
                  estilo: AppText.corpo,
                  tamanho: 14,
                  cor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: Botao(
                  texto: 'Voltar',
                  backgroundColor: Cores.azul,
                  textColor: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
