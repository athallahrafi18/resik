import 'package:flutter/material.dart';
import 'fragments/user/daftar_user.dart';
import 'fragments/setor/daftar_setor.dart';
import 'fragments/pengaturan/pengaturan.dart';
import 'fragments/reward/daftar_reward.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class DashboardSummary {
  final int totalTransaksi;
  final int pending;
  final int diproses;
  final int selesai;
  final int totalUser;

  DashboardSummary({
    required this.totalTransaksi,
    required this.pending,
    required this.diproses,
    required this.selesai,
    required this.totalUser,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalTransaksi: json['total_transaksi'] ?? 0,
      pending: json['pending'] ?? 0,
      diproses: json['diproses'] ?? 0,
      selesai: json['selesai'] ?? 0,
      totalUser: json['total_user'] ?? 0,
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final apiUrl = dotenv.env['API_URL'];
    final response = await http.get(Uri.parse('$apiUrl/api/dashboard-summary'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      setState(() {
        _summary = DashboardSummary.fromJson(jsonData);
      });
    } else {
      print("Gagal fetch summary: ${response.statusCode}");
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with teal background
          Container(
            color: const Color(0xFF26A69A),
            padding: const EdgeInsets.only(top: 30, bottom: 15, left: 15, right: 15),
            width: double.infinity,
            child: const SizedBox(height: 24), // Spacer for status bar
          ),
          
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    Row(
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
                                'Saat ini anda berada di halaman admin!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Circle avatar with user info
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
                                'Total User: ${_summary?.totalUser ?? 0}',
                                style: TextStyle(
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
                    
                    const SizedBox(height: 30),
                    
                    // Statistics row 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Total Transaksi
                        _buildStatisticItem(
                          icon: Icons.check_circle_outline,
                          title: 'Total Transaksi',
                          value: _summary?.totalTransaksi.toString() ?? '-',
                          color: const Color(0xFFE0F2F1),
                          iconColor: const Color(0xFF26A69A),
                        ),
                        
                        // Menunggu
                        _buildStatisticItem(
                          icon: Icons.autorenew,
                          title: 'Menunggu',
                          value: _summary?.pending.toString() ?? '-',
                          color: const Color(0xFFE0F2F1),
                          iconColor: const Color(0xFF26A69A),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Statistics row 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Diproses
                        _buildStatisticItem(
                          icon: Icons.shopping_cart_outlined,
                          title: 'Diproses',
                          value: _summary?.diproses.toString() ?? '-',
                          color: const Color(0xFFE0F2F1),
                          iconColor: const Color(0xFF26A69A),
                        ),
                        
                        // Selesai
                        _buildStatisticItem(
                          icon: Icons.verified_outlined,
                          title: 'Selesai',
                          value: _summary?.selesai.toString() ?? '-',
                          color: const Color(0xFFE0F2F1),
                          iconColor: const Color(0xFF26A69A),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Menu buttons row 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Daftar Setor Sampah
                        _buildMenuButton(
                          icon: Icons.receipt_long_outlined,
                          title: 'Daftar Setor Sampah',
                          onTap: () {
                            // Navigasi ke halaman Daftar Setor Sampah
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DaftarSetorFragment(),
                              ),
                            );
                          },
                        ),
                        
                        // Daftar User
                        _buildMenuButton(
                          icon: Icons.people_outline,
                          title: 'Daftar User',
                          onTap: () {
                            // Navigasi ke halaman Daftar User
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DaftarUserFragment(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Menu buttons row 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Pengaturan
                        _buildMenuButton(
                          icon: Icons.settings_outlined,
                          title: 'Pengaturan',
                          onTap: () {
                            // Navigasi ke halaman Pengaturan
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PengaturanFragment(),
                              ),
                            );
                          },
                        ),
                        
                        // Riwayat
                        _buildMenuButton(
                          icon: Icons.wallet,
                          title: 'Daftar Reward',
                          onTap: () {
                            // Navigation logic here
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DaftarRewardFragment(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color(0xFF26A69A),
      //   onPressed: () {
      //     // Add action here
      //   },
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(  // Added Expanded to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,  // Added for text overflow
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF26A69A),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF26A69A),
              ),
              overflow: TextOverflow.ellipsis,  // Added for text overflow
            ),
          ],
        ),
      ),
    );
  }
}