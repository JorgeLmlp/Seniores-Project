import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'services/app_settings.dart';
import 'package:flutter/material.dart';
// import 'pages/tela_cadastro.dart';
import 'pages/auth/tela_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (_) => const SenioresApp(),
  ));
}

class SenioresApp extends StatelessWidget {
  const SenioresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: AppSettings.instance,
        builder: (_, mode, __) => MaterialApp(
                useInheritedMediaQuery: true,
              locale: const Locale('pt', 'BR'),
              supportedLocales: const [Locale('pt', 'BR')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              themeMode: mode,
              theme: ThemeData(
                  useMaterial3: true,
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: const Color(0xFF275DAD))),
              darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: const Color(0xFF80AFF5),
                      brightness: Brightness.dark)),
              builder: (context, child) => DevicePreview.appBuilder(
                context,
                Builder(
                    builder: (previewContext) => MediaQuery(
                          data: MediaQuery.of(previewContext)
                              .copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        )),
              ),
              debugShowCheckedModeBanner: false,
              title: 'Seniores',
              home: const Login(),
            ));
  }
}
