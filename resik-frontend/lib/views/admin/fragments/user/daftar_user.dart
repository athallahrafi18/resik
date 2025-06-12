import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String subtitle;

  UserModel({required this.id, required this.name, required this.subtitle});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String subtitleText = '';
    if (json['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(json['createdAt']);
        subtitleText =
            'Bergabung ${DateFormat('d MMMM y', 'id_ID').format(dt)}';
      } catch (_) {
        subtitleText = json['email'] ?? '-';
      }
    } else {
      subtitleText = json['email'] ?? '-';
    }
    return UserModel(
      id: json['id'] ?? '',
      name: json['username'] ?? '-',
      subtitle: subtitleText,
    );
  }
}

class DaftarUserFragment extends StatefulWidget {
  const DaftarUserFragment({Key? key}) : super(key: key);

  @override
  State<DaftarUserFragment> createState() => _DaftarUserFragmentState();
}

class _DaftarUserFragmentState extends State<DaftarUserFragment> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final response = await http.get(Uri.parse('$apiUrl/api/users'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _users = data.map((e) => UserModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data user: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat memuat data user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final url = Uri.parse('$apiUrl/api/users/$userId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((item) => item.id == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil dihapus'),
            backgroundColor: Color(0xFF26A69A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus user: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat menghapus user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Apakah Anda yakin ingin menghapus user "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(UserModel user, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF26A69A),
          radius: 25,
          child: Icon(
            Icons.person_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: Color(0xFF26A69A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user.subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () {
            _showDeleteConfirmation(context, user);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Daftar User',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat Datang!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF26A69A),
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Saat ini anda berada di halaman Daftar User!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE0F2F1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total User: ${_users.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  'Lokasi: Kabupaten Bandung',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return _buildUserItem(user, context);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
