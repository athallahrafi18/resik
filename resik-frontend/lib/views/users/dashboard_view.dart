import 'package:flutter/material.dart';
import 'fragments/dashboard.dart';
import 'fragments/orders.dart';
import 'fragments/scan.dart';
import 'fragments/notifications.dart';
import 'fragments/profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:badges/badges.dart' as badges;

class DashboardView extends StatefulWidget {
  final int initialTab;
  const DashboardView({super.key, this.initialTab = 0});

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;

    // Kirim FCM token saat pertama kali masuk dashboard
    _sendFcmToken();

    // Listener FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('🔄 Token FCM berubah: $newToken');
      await _sendFcmToken(token: newToken);
    });
  }

  Future<void> _sendFcmToken({String? token}) async {
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final apiUrl = dotenv.env['API_URL'];
      if (idToken != null && fcmToken != null && apiUrl != null) {
        final response = await http.post(
          Uri.parse('$apiUrl/api/auth/update-fcm-token'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"token": idToken, "fcmToken": fcmToken}),
        );
        print('FCM Token sent to backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }

  final List<Widget> _pages = [
    DashboardFragment(),
    OrdersFragment(),
    ScanFragment(),
    NotificationsFragment(),
    ProfileFragment(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Stream<int> get unreadNotifCountStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Pesanan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Pindai',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: unreadNotifCountStream,
              builder: (context, snapshot) {
                int unread = snapshot.data ?? 0;
                return badges.Badge(
                  showBadge: unread > 0,
                  badgeContent: Text(
                    unread > 99 ? "99+" : unread.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  position: badges.BadgePosition.topEnd(top: -12, end: -10),
                  child: const Icon(Icons.notifications),
                );
              },
            ),
            label: 'Notifikasi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
