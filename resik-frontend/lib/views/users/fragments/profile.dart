import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'change_profile.dart';
import '../../login_view.dart';
import 'package:resik/views/users/dashboard_view.dart';

class ProfileFragment extends StatefulWidget {
  @override
  State<ProfileFragment> createState() => _ProfileFragmentState();
}

class _ProfileFragmentState extends State<ProfileFragment> {
  String username = '-';
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';
      if (userId.isEmpty) {
        setState(() {
          errorMsg = "User belum login";
          isLoading = false;
        });
        return;
      }
      final apiUrl = dotenv.env['API_URL'];
      final url = '$apiUrl/api/users/$userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? '-';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = "Gagal memuat profil";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Terjadi kesalahan: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Profil',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.teal[100],
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        AssetImage('assets/images/profile_picture.png'),
                  ),
                  SizedBox(height: 12),
                  isLoading
                      ? CircularProgressIndicator()
                      : errorMsg != null
                          ? Text(
                              errorMsg!,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            )
                          : Text(
                              username,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[800]),
                            ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Tunggu halaman ChangeProfileFragment selesai
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeProfileFragment(),
                        ),
                      );
                      // Kalau kembali dari halaman edit dengan result == true, refresh profil
                      if (result == true && mounted) {
                        setState(() {
                          isLoading = true;
                        });
                        fetchProfile(); // panggil ulang fetch data
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Edit Profil',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            buildSectionHeader('Tentang'),
            buildListItem(Icons.info_outline, 'Panduan', onTap: () {}),
            buildListItem(Icons.description_outlined, 'Syarat dan Ketentuan',
                onTap: () {}),
            buildListItem(Icons.privacy_tip_outlined, 'Kebijakan Privasi',
                onTap: () {}),
            buildListItem(Icons.help_outline, 'Pertanyaan Umum', onTap: () {}),
            SizedBox(height: 20),
            buildSectionHeader('Lainnya'),
            buildListItem(Icons.info, 'Versi Aplikasi', onTap: () {}),
            buildListItem(Icons.logout, 'Keluar', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginView()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[300],
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
    );
  }

  Widget buildListItem(IconData icon, String title,
      {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
      ),
      onTap: onTap,
    );
  }
}
