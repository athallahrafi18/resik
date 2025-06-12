import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:resik/views/users/dashboard_view.dart';

// Navigator global untuk seluruh aplikasi
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi FCM dan notifikasi lokal
  static Future<void> initialize() async {
    // Pengaturan notifikasi lokal
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == 'open_notification') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => DashboardView(initialTab: 3)),
            (route) => false,
          );
        }
      },
    );

    // Izin notifikasi (iOS)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  /// Dapatkan token FCM user saat ini
  static Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  /// Tampilkan notifikasi lokal (saat app foreground)
  static void showLocalNotification(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'Notifikasi',
      channelDescription: 'Notifikasi Aplikasi',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notifDetails =
        NotificationDetails(android: androidDetails);

    _localNotificationsPlugin.show(
      notif.hashCode,
      notif.title,
      notif.body,
      notifDetails,
      payload: 'open_notification', // Penting! Supaya handler navigasi bisa jalan
    );
  }

  /// Listener FCM -- panggil di SplashView atau saat login
  static void setupFCMListener(BuildContext context) {
    // Notifikasi saat app foreground (langsung tampil lokal)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
    });

    // Jika notifikasi di-tap (app background/minimized)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardView(initialTab: 3)),
        (route) => false,
      );
    });

    // Jika app di-launch DARI notifikasi (benar-benar terminated)
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DashboardView(initialTab: 3)),
          (route) => false,
        );
      }
    });
  }
}
