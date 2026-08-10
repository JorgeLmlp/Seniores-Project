/*Essa tela vai ser responsavel apenas para iniciar o app.
Caso o usuario ja esteja logado, ele vai direto para a tela
home, se nao, ele vai para a tela de login. */

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'pages/tela_inicio.dart';
// import 'pages/tela_cadastro.dart';
 import 'pages/tela_login.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const SenioresApp(),
    ),
  );
}

class SenioresApp extends StatelessWidget {
  const SenioresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'Seniores',
      home: const Login(),
    );
  }
}