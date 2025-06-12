import 'package:flutter/material.dart';
import 'register_view.dart';
import 'users/dashboard_view.dart' as user;
import 'admin/dashboard_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserData {
  final String email;
  final String password;
  final String role;

  UserData(this.email, this.password, this.role);
}

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email dan password harus diisi';
        _isLoading = false;
      });
      return;
    }

    try {
      // Login ke Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception("Gagal mengambil idToken");
      }

      final apiUrl = dotenv.env['API_URL'];

      // Ambil FCM token setelah login berhasil
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Kirim ke backend untuk cek role
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        final uid = data['uid'];

        // Kirim FCM token ke backend untuk disimpan di Firestore
        if (fcmToken != null && uid != null) {
          await http.post(
            Uri.parse('$apiUrl/api/auth/update-fcm-token'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"uid": uid, "fcmToken": fcmToken}),
          );
        }

        // Navigasi
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardView()),
          );
        } else if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => user.DashboardView()),
          );
        } else {
          setState(() {
            _errorMessage = 'Role tidak dikenali';
          });
        }
      } else {
        final message = jsonDecode(response.body)['message'];
        setState(() {
          _errorMessage = message ?? 'Login gagal. Silakan coba lagi.';
        });
      }
    } catch (e) {
      String message = 'Login gagal. Silakan coba lagi.';

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Email atau password salah.';
        } else {
          message = e.message ?? 'Terjadi kesalahan autentikasi.';
        }
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Text(
                'Masuk Akun',
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              SizedBox(height: 8),
              Text(
                'Silahkan isi data dibawah ini untuk melanjutkan',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 24),
              buildEmailField(),
              buildPasswordField(),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'MASUK',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterView()),
                          );
                        },
                  child: Text(
                    'Belum punya akun? Daftar di sini',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'EMAIL',
          labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          labelText: 'PASSWORD',
          labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.teal),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
