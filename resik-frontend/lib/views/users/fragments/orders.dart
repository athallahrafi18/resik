import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resik/views/admin/fragments/setor/daftar_setor_nota.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:resik/views/users/dashboard_view.dart';

class SetorSampahModel {
  final String id;
  final String orderId;
  final String nama;
  final String status;
  final String tanggal;

  SetorSampahModel({
    required this.id,
    required this.orderId,
    required this.nama,
    required this.status,
    required this.tanggal,
  });

  factory SetorSampahModel.fromJson(Map<String, dynamic> json) {
    return SetorSampahModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      nama: json['nama'] ?? '',
      status: json['status'] ?? 'Pending',
      tanggal: json['tanggal'] != null
          ? DateFormat('dd MMM yyyy', 'id_ID')
              .format(DateTime.parse(json['tanggal']).toLocal())
          : '',
    );
  }
}

class OrdersFragment extends StatefulWidget {
  @override
  _OrdersFragmentState createState() => _OrdersFragmentState();
}

class _OrdersFragmentState extends State<OrdersFragment> {
  int _selectedTab = 0;
  List<SetorSampahModel> _setoran = [];
  bool _isLoading = true;

  final List<String> statusBerlangsung = ['Pending', 'Pickup', 'Arrived', 'Diproses'];

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await initializeDateFormatting('id_ID', null);
    await _fetchSetoran();
  }

  Future<void> _fetchSetoran() async {
    try {
      final apiUrl = dotenv.env['API_URL'];
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        print('User belum login.');
        return;
      }

      final response = await http.get(
        Uri.parse('$apiUrl/api/setoran?uid=$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<SetorSampahModel> loaded = data
            .map((jsonItem) => SetorSampahModel.fromJson(jsonItem))
            .toList();

        final adaSedangBerlangsung = loaded.any(
          (item) => statusBerlangsung.contains(item.status),
        );

        setState(() {
          _setoran = loaded;
          _selectedTab = adaSedangBerlangsung ? 0 : 1;
          _isLoading = false;
        });
      } else {
        print('Gagal fetch setoran: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  List<SetorSampahModel> get _filtered {
    if (_selectedTab == 0) {
      return _setoran.where((item) => statusBerlangsung.contains(item.status)).toList();
    } else {
      return _setoran.where((item) => item.status == 'Selesai').toList();
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Pesanan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardView(initialTab: 0)),
              (route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildTabButton('Sedang Berlangsung', 0),
                buildTabButton('Selesai', 1),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? buildEmptyOrdersView()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final setor = _filtered[index];
                          return buildSetorItem(setor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget buildTabButton(String title, int index) {
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _selectedTab == index ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: _selectedTab == index ? Colors.white : Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildSetorItem(SetorSampahModel setor) {
    Color statusColor;
    IconData statusIcon;

    switch (setor.status) {
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'Pickup':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'Arrived':
        statusColor = Colors.purple;
        statusIcon = Icons.place;
        break;
      case 'Diproses':
        statusColor = Colors.amber;
        statusIcon = Icons.autorenew;
        break;
      case 'Selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF26A69A),
          radius: 25,
          child: Text(
            setor.orderId.substring(setor.orderId.length - 3),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          setor.nama,
          style: const TextStyle(
            color: Color(0xFF26A69A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  setor.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Order ID: ${setor.orderId} • ${setor.tanggal}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: setor.status == 'Selesai'
            ? IconButton(
                icon: const Icon(Icons.receipt_long, color: Color(0xFF26A69A)),
                tooltip: 'Lihat Nota',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetorNotaView(id: setor.id, isAdmin: false),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/empty.png', height: 150),
          const SizedBox(height: 16),
          Text(
            'Belum ada data setoran.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
