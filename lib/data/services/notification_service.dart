import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription.dart';

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.payload}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _prefsDailyReminder = 'daily_reminder_enabled';
  static const String _prefsDailyReminderHour = 'daily_reminder_hour';

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
    _initialized = true;
  }

  /// Pianifica notifiche per abbonamento in scadenza
  Future<void> scheduleSubscriptionReminder(Subscription sub) async {
    if (!sub.reminderEnabled || !sub.isActive) return;

    final reminderDate = sub.nextPaymentDate.subtract(
      Duration(days: sub.reminderDaysBefore),
    );

    if (reminderDate.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id: sub.id.hashCode,
        title: 'Pagamento in arrivo 💳',
        body: '${sub.name}: €${sub.amount.toStringAsFixed(2)} ${sub.frequency == SubscriptionFrequency.yearly ? "annuale" : sub.frequency == SubscriptionFrequency.monthly ? "mensile" : "settimanale"} tra ${sub.reminderDaysBefore} ${sub.reminderDaysBefore == 1 ? "giorno" : "giorni"}',
        scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_reminders',
            'Promemoria Abbonamenti',
            channelDescription: 'Notifiche per pagamenti abbonamenti in scadenza',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Errore pianificazione notifica: $e');
    }
  }

  /// Cancella notifica di un abbonamento
  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    await _plugin.cancel(id: subscriptionId.hashCode);
  }

  /// Pianifica tutte le notifiche per gli abbonamenti attivi
  Future<void> scheduleAllSubscriptionReminders(List<Subscription> subs) async {
    // Cancella tutte le precedenti
    await _plugin.cancelAll();

    for (final sub in subs) {
      await scheduleSubscriptionReminder(sub);
    }

    // Ripianifica il promemoria giornaliero se attivo
    await _scheduleDailyReminderIfEnabled();
  }

  /// Abilita/disabilita il promemoria giornaliero per inserire spese
  Future<void> setDailyReminder(bool enabled, {int hour = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsDailyReminder, enabled);
    await prefs.setInt(_prefsDailyReminderHour, hour);

    if (enabled) {
      await _scheduleDailyReminder(hour);
    } else {
      await _plugin.cancel(id: -1); // ID speciale per daily reminder
    }
  }

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsDailyReminder) ?? false;
  }

  Future<int> getDailyReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsDailyReminderHour) ?? 20;
  }

  Future<void> _scheduleDailyReminderIfEnabled() async {
    final enabled = await isDailyReminderEnabled();
    if (enabled) {
      final hour = await getDailyReminderHour();
      await _scheduleDailyReminder(hour);
    }
  }

  Future<void> _scheduleDailyReminder(int hour) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: -1,
        title: 'Hai tracciato le spese di oggi? 📝',
        body: 'Apri Spendly per registrare le tue spese giornaliere',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Promemoria Giornaliero',
            channelDescription: 'Promemoria per inserire le spese giornaliere',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Errore pianificazione promemoria giornaliero: $e');
    }
  }

  /// Mostra notifica istantanea di superamento budget
  Future<void> showBudgetExceededNotification(String categoryName, double spent, double budget) async {
    try {
      await _plugin.show(
        id: categoryName.hashCode + 10000,
        title: 'Budget superato! ⚠️',
        body: '$categoryName: speso €${spent.toStringAsFixed(2)} su €${budget.toStringAsFixed(2)}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts',
            'Avvisi Budget',
            channelDescription: 'Notifiche per superamento budget',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Errore notifica budget: $e');
    }
  }
}
