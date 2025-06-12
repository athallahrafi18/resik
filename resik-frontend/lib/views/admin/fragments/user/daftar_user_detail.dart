import 'package:flutter/material.dart';
import 'daftar_user_detail_edit.dart';

class UserDetailModel {
  final String id;
  String nama;
  String username;
  String email;
  String telepon;
  String lokasi;
  final String tanggalBergabung;
  bool isActive;

  UserDetailModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.email,
    required this.telepon,
    required this.lokasi,
    required this.tanggalBergabung,
    required this.isActive,
  });
}

class DaftarUserDetailView extends StatefulWidget {
  final String userId;

  const DaftarUserDetailView({Key? key, required this.userId}) : super(key: key);

  @override
  State<DaftarUserDetailView> createState() => _DaftarUserDetailViewState();
}

class _DaftarUserDetailViewState extends State<DaftarUserDetailView> {
  late UserDetailModel user;

  @override
  void initState() {
    super.initState();
    // Simulasi data pengguna
    user = UserDetailModel(
      id: widget.userId,
      nama: 'Khoerunisa Alfin',
      username: 'khoerunisa alfin',
      email: 'khoerunisaalfin@gmail.com',
      telepon: '+63-280-555-8376',
      lokasi: 'Bank Sampah Kabupaten Bandung',
      tanggalBergabung: '7 Januari 2025',
      isActive: true,
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
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildInfoSection('Username :', user.username),
                _buildInfoSection('Email :', user.email),
                _buildInfoSection('Nomor Telepon :', user.telepon),
                _buildInfoSection('Lokasi :', user.lokasi),
              ],
            ),
          ),
          // FAB untuk edit
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF26A69A),
              onPressed: () {
                _navigateToEditProfile();
              },
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Nama pengguna
          Text(
            user.nama,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26A69A),
            ),
          ),
          const SizedBox(height: 15),
          // Profil image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF26A69A), width: 3),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 60,
              color: Color(0xFF26A69A),
            ),
          ),
          const SizedBox(height: 15),
          // Details
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Bergabung ${user.tanggalBergabung}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFB2DFDB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF26A69A), width: 1),
            ),
            child: Text(
              user.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF26A69A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: const Color(0xFFF0F9F8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF26A69A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete action
              _showDeleteConfirmation(label.replaceAll(' :', ''));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $field'),
        content: Text('Are you sure you want to delete the $field?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$field deleted successfully'),
                  backgroundColor: const Color(0xFF26A69A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaftarUserDetailEditView(userId: user.id),
      ),
    );
    
    // Update user data if result is returned
    if (result != null && result is UserEditModel) {
      setState(() {
        user.username = result.username;
        user.email = result.email;
        user.telepon = result.telepon;
      });
    }
  }
}