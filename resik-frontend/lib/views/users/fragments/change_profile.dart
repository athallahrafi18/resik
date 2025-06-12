import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChangeProfileFragment extends StatefulWidget {
  @override
  State<ChangeProfileFragment> createState() => _ChangeProfileFragmentState();
}

class _ChangeProfileFragmentState extends State<ChangeProfileFragment> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  bool isLoading = true;
  String? errorMsg;
  String? joinDate;
  String? profileName;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    fetchProfile();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
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
        usernameController.text = data['username'] ?? '';
        profileName = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        if (data['createdAt'] != null) {
          DateTime dt = DateTime.parse(data['createdAt']);
          joinDate = 'Bergabung ${DateFormat('d MMMM y', 'id_ID').format(dt)}';
        } else {
          joinDate = '';
        }
        setState(() {
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

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';
      final apiUrl = dotenv.env['API_URL'];
      final url = '$apiUrl/api/users/$userId';

      final body = {
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
      };

      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        Navigator.pop(context, true); // Kembali ke profil dengan refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil berhasil diperbarui"), backgroundColor: Colors.teal),
        );
      } else {
        setState(() {
          isLoading = false;
          errorMsg = "Gagal menyimpan profil";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = "Terjadi kesalahan: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Edit Profil',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.teal[100],
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            AssetImage('assets/images/profile_picture.png'),
                      ),
                      SizedBox(height: 12),
                      Text(
                        profileName ?? usernameController.text,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.teal[50],
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          buildProfileField(
                            'USERNAME :',
                            usernameController,
                            Icons.person,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Username tidak boleh kosong'
                                : null,
                          ),
                          buildProfileField(
                            'EMAIL :',
                            emailController,
                            Icons.email,
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Email tidak boleh kosong'
                                : null,
                          ),
                          buildProfileField(
                            'NOMOR TELEPON :',
                            phoneController,
                            Icons.phone,
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              joinDate ?? '',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ),
                          if (errorMsg != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Center(
                                  child: Text(
                                errorMsg!,
                                style: TextStyle(color: Colors.red),
                              )),
                            ),
                          SizedBox(height: 18),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                              ),
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text(
                                "Simpan",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildProfileField(
      String label, TextEditingController controller, IconData icon,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                TextFormField(
                  controller: controller,
                  validator: validator,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
                Divider(color: Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
