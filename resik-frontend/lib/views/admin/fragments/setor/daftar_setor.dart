import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

import 'daftar_setor_detail.dart';

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

class DaftarSetorFragment extends StatefulWidget {
  const DaftarSetorFragment({Key? key}) : super(key: key);

  @override
  State<DaftarSetorFragment> createState() => _DaftarSetorFragmentState();
}

class _DaftarSetorFragmentState extends State<DaftarSetorFragment> {
  final List<String> _statusOptions = [
    'Semua',
    'Pending',
    'Pickup',
    'Arrived',
    'Diproses',
    'Selesai'
  ];
  String _selectedStatus = 'Semua';

  List<SetorSampahModel> _setorList = [];

  @override
  void initState() {
    super.initState();
    _fetchSetoranData();
    _initializeLocaleAndFetchData();
  }

  Future<void> _initializeLocaleAndFetchData() async {
    await initializeDateFormatting('id_ID', null);
    await _fetchSetoranData();
  }

  Future<void> _fetchSetoranData() async {
    try {
      final apiUrl = dotenv.env['API_URL'];
      final queryParam =
          _selectedStatus != 'Semua' ? '?status=$_selectedStatus' : '';

      final response = await http.get(
        Uri.parse('$apiUrl/api/setoran$queryParam'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<SetorSampahModel> loadedSetoran =
            data.map((jsonItem) => SetorSampahModel.fromJson(jsonItem)).toList();

        setState(() {
          _setorList = loadedSetoran;
        });
      } else {
        print('Gagal ambil data dari backend: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error saat ambil data: $e');
    }
  }

  List<SetorSampahModel> get _filteredList => _setorList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF26A69A),
            padding:
                const EdgeInsets.only(top: 40, bottom: 15, left: 15, right: 15),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title dan Dropdown filter
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Setor Sampah',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF26A69A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.filter_list,
                                color: Color(0xFF26A69A)),
                            style: const TextStyle(color: Color(0xFF26A69A)),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                                _fetchSetoranData();
                              }
                            },
                            items: _statusOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),

                  // Daftar setoran
                  Expanded(
                    child: _filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada data setor sampah',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredList.length,
                            itemBuilder: (context, index) {
                              final setor = _filteredList[index];
                              return _buildSetorItem(setor);
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

  Widget _buildSetorItem(SetorSampahModel setor) {
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

    return InkWell(
      onTap: () async {
        print('➡️ Buka detail untuk ID: ${setor.id}');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetorDetailView(id: setor.id),
          ),
        );
        if (result == 'updated') {
          await _fetchSetoranData();
        }
      },
      child: Container(
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
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 12,
                  ),
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
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF26A69A)),
            onSelected: (String result) {
              if (result == 'detail') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetorDetailView(id: setor.id),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'detail',
                child: Text('Lihat Detail'),
              ),
              const PopupMenuItem<String>(
                value: 'update',
                child: Text('Update Status'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Hapus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
