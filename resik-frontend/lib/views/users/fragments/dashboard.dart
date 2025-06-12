import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'riwayat.dart';
import 'scan.dart';
import 'location.dart';
import 'reward.dart';
import 'bantuan.dart';
import 'panduan.dart';

class DashboardFragment extends StatefulWidget {
  @override
  State<DashboardFragment> createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment> {
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      setState(() {
        username = '';
        isLoading = false;
      });
      return;
    }

    final apiUrl = 'http://192.168.1.3:5000/api/users/$uid';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        setState(() {
          username = data['username'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          username = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        username = '';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  isLoading
                      ? SizedBox(
                          width: 80,
                          height: 18,
                          child: LinearProgressIndicator(),
                        )
                      : Text(
                          username ?? '',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                ],
              ),
              Icon(Icons.notifications, color: Colors.teal, size: 28),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sampah Terkumpul',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RiwayatFragment(userId: uid)),
                    );
                  },
                  child: Text(
                    'Riwayat',
                    style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mari siapkan dan jadwalkan sampahmu!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),
                Image.asset('assets/images/preparation_image.png', height: 60),
              ],
            ),
          ),
          SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              buildDashboardItem(
                  context, Icons.assignment, 'Setor Sampah', ScanFragment()),
              buildDashboardItem(
                  context, Icons.location_on, 'Lokasi', LocationFragment()),
              buildDashboardItem(
                  context, Icons.card_giftcard, 'Reward', RewardFragment()),
              buildDashboardItem(
                  context, Icons.help_outline, 'Bantuan', BantuanFragment()),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Hai! Siap untuk belajar cara mengubah sampah menjadi poin? Mari kita baca panduannya!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PanduanFragment()),
                    );
                  },
                  child: Text(
                    'Panduan',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Informasi Terkini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: PageView(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/banner.png',
                      fit: BoxFit.cover),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/banner2.png',
                      fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashboardItem(
      BuildContext context, IconData icon, String title, Widget targetPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.teal[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.teal),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800]),
            ),
          ],
        ),
      ),
    );
  }
}
