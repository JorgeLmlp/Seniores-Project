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
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Cores.preto, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const AppText(
                      texto: 'Detalhes do Comunicado',
                      estilo: AppText.titulo,
                      tamanho: 22),
                ],
              ),
              const SizedBox(height: 32),
              const AppText(
                  texto: 'Destinatário',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Cores.cinza.withOpacity(0.3)),
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
                    const SizedBox(height: 4),
                    AppText(
                      texto: 'Vínculo: ${destinatario.vinculo}',
                      estilo: AppText.corpo,
                      tamanho: 14,
                      cor: Cores.cinza,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      texto: 'WhatsApp: ${destinatario.telefone}',
                      estilo: AppText.corpo,
                      tamanho: 14,
                      cor: Cores.cinza,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const AppText(
                  texto: 'Mensagem Enviada',
                  estilo: AppText.titulo,
                  tamanho: 18,
                  cor: Cores.azul),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Cores.cinza.withOpacity(0.3)),
                ),
                child: AppText(
                  texto: mensagem.isEmpty
                      ? 'Nenhuma mensagem informada.'
                      : mensagem,
                  estilo: AppText.corpo,
                  tamanho: 14,
                  cor: Cores.preto,
                ),
              ),
              const Spacer(),
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
