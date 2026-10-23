/*Essa tela vai ser responsavel apenas para iniciar o app.
Caso o usuario ja esteja logado, ele vai direto para a tela
home, se nao, ele vai para a tela de login. */

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pages/tela_inicio.dart';
import 'pages/tela_login.dart';
import 'services/session_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.inicializar();
  var restaurada = await SessionService.instance.restaurar();
  if (restaurada) {
    try {
      await ApiService().obterUsuario(
        tipo: SessionService.instance.tipoUsuario!,
        usuarioId: SessionService.instance.usuarioId!,
      );
    } on ApiException {
      await SessionService.instance.encerrar();
      restaurada = false;
    }
  }
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => SenioresApp(sessaoRestaurada: restaurada),
    ),
  );
}

class SenioresApp extends StatelessWidget {
  final bool sessaoRestaurada;

  const SenioresApp({super.key, required this.sessaoRestaurada});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'Seniores',
      home: sessaoRestaurada ? const Home() : const Login(),
    );
  }
}
