import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicamento.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir'),
    );
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _inicializado = true;
  }

  static Future<void> sincronizar(List<Medicamento> medicamentos) async {
    await inicializar();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medicamentos',
        'Medicamentos',
        channelDescription: 'Lembretes dos horários de medicamentos',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    for (final medicamento in medicamentos) {
      if (!medicamento.alertaSonoro && medicamento.horarios.isEmpty) continue;
      for (var indice = 0; indice < medicamento.horarios.length; indice++) {
        final partes = medicamento.horarios[indice].split(':');
        if (partes.length != 2) continue;
        final hora = int.tryParse(partes[0]);
        final minuto = int.tryParse(partes[1]);
        if (hora == null || minuto == null || hora > 23 || minuto > 59) {
          continue;
        }
        final agora = tz.TZDateTime.now(tz.local);
        var proximo = tz.TZDateTime(
          tz.local,
          agora.year,
          agora.month,
          agora.day,
          hora,
          minuto,
        );
        if (proximo.isBefore(agora)) {
          proximo = proximo.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          _id(medicamento.id ?? 0, indice),
          medicamento.nome,
          'Horário de ${medicamento.dosagem}',
          proximo,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  static int _id(int medicamentoId, int indice) => medicamentoId * 100 + indice;
}
