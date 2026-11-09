import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens only explicit HTTP(S) maps, telephone or WhatsApp URLs.
class AcoesExternas {
  static Future<void> _abrir(BuildContext context, Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'tel') return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) { /* The platform may not have a handler installed. */ }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não há aplicativo disponível para abrir este endereço.')));
    }
  }

  static Future<void> mapa(BuildContext context, String endereco) async {
    if (endereco.trim().isEmpty) return;
    await _abrir(context, Uri.https('www.google.com', '/maps/search/',
      {'api': '1', 'query': endereco.trim()}));
  }

  static Future<void> telefone(BuildContext context, String numero) async {
    final digits = numero.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    await _abrir(context, Uri(scheme: 'tel', path: digits));
  }

  static Future<void> whatsapp(BuildContext context, String numero) async {
    final digits = numero.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final internacional = digits.startsWith('55') ? digits : '55$digits';
    await _abrir(context, Uri.https('wa.me', '/$internacional'));
  }
}
