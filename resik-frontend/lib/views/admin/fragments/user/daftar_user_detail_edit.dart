import 'package:flutter/material.dart';

class UserEditModel {
  String id;
  String nama;
  String username;
  String email;
  String telepon;
  String lokasi;
  String tanggalBergabung;
  bool isActive;

  UserEditModel({
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

class DaftarUserDetailEditView extends StatefulWidget {
  final String userId;

  const DaftarUserDetailEditView({Key? key, required this.userId}) : super(key: key);

  @override
  State<DaftarUserDetailEditView> createState() => _DaftarUserDetailEditViewState();
}

class _DaftarUserDetailEditViewState extends State<DaftarUserDetailEditView> {
  late UserEditModel user;
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Simulasi data pengguna
    user = UserEditModel(
      id: widget.userId,
      nama: 'Khoerunisa Alfin',
      username: 'khoerunisa alfin',
      email: 'khoerunisaalfin@gmail.com',
      telepon: '+63-280-555-8376',
      lokasi: 'Bank Sampah Kabupaten Bandung',
      tanggalBergabung: '7 Januari 2025',
      isActive: true,
    );
    
    // Set nilai awal controller
    _usernameController.text = user.username;
    _emailController.text = user.email;
    _teleponController.text = user.telepon;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    super.dispose();
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
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Username field
              _buildInputField(
                label: 'Username :',
                controller: _usernameController,
                hint: 'Edit Username',
              ),
              
              const SizedBox(height: 20),
              
              // Email field
              _buildInputField(
                label: 'Email :',
                controller: _emailController,
                hint: 'Edit Email',
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 20),
              
              // Phone field
              _buildInputField(
                label: 'Nomor Telepon :',
                controller: _teleponController,
                hint: 'Edit Nomor Telepon',
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 40),
              
              // Edit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _saveChanges() {
    // Update the user model with new values
    setState(() {
      user.username = _usernameController.text;
      user.email = _emailController.text;
      user.telepon = _teleponController.text;
    });

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile berhasil diperbarui'),
        backgroundColor: Color(0xFF26A69A),
      ),
    );

    // Navigate back to the detail page
    Navigator.pop(context, user);
  }
}