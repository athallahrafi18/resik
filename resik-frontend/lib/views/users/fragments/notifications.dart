import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resik/views/users/dashboard_view.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime dateTime;
  final String type;
  final bool isRead;
  final String setoranId;

  AppNotification({
    required this.title,
    required this.body,
    required this.dateTime,
    this.type = "info",
    required this.isRead,
    required this.setoranId,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      dateTime: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? "info",
      isRead: data['isRead'] ?? false,
      setoranId: data['setoran_id'] ?? '',
    );
  }
}

class NotificationsFragment extends StatefulWidget {
  const NotificationsFragment({Key? key}) : super(key: key);

  @override
  State<NotificationsFragment> createState() => _NotificationsFragmentState();
}

class _NotificationsFragmentState extends State<NotificationsFragment> {
  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unreadQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadQuery.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  String formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
    }
  }

  IconData getIcon(String type) {
    switch (type) {
      case "success":
        return Icons.check_circle_rounded;
      case "reward":
        return Icons.card_giftcard_rounded;
      case "error":
        return Icons.error_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color getIconColor(String type) {
    switch (type) {
      case "success":
        return Colors.green;
      case "reward":
        return Colors.amber[700]!;
      case "error":
        return Colors.redAccent;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Notifikasi')),
        body: Center(child: Text("Silakan login terlebih dahulu.")),
      );
    }

    final notifRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Notifikasi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardView(initialTab: 0)),
              (route) => false,
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notifRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat notifikasi'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/empty.png', height: 150),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }
          final notifications = docs.map((d) => AppNotification.fromFirestore(d)).toList();
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Card(
                color: notif.isRead ? Colors.grey[100] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 1.5,
                child: ListTile(
                  leading: Icon(
                    getIcon(notif.type),
                    color: getIconColor(notif.type),
                    size: 32,
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  trailing: Text(
                    formatDate(notif.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  // Tidak perlu onTap untuk update isRead lagi!
                ),
              );
            },
          );
        },
      ),
    );
  }
}
