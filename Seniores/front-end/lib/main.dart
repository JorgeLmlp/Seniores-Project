import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'services/app_settings.dart';
import 'services/session_service.dart';
import 'package:flutter/material.dart';
import 'pages/auth/tela_login.dart';
import 'pages/tela_inicio.dart';
import 'pages/tela_vinculos.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await SessionService.instance.restaurar();
  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (_) => const SenioresApp()),
  );
}

class SenioresApp extends StatelessWidget {
  const SenioresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.instance,
        SessionService.instance,
      ]),
      builder: (_, __) {
        final session = SessionService.instance;
        return MaterialApp(
          key: ValueKey('${session.autenticado}:${session.tipoUsuario}'),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          themeMode: AppSettings.instance.value,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          builder: (context, child) => DevicePreview.appBuilder(
            context,
            Builder(
              builder: (previewContext) => MediaQuery(
                data: MediaQuery.of(
                  previewContext,
                ).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          title: 'Seniores',
          home: !session.autenticado
              ? const Login()
              : session.tipoUsuario == 'paciente'
                  ? const Home()
                  : const Vinculos(),
        );
      },
    );
  }
}
