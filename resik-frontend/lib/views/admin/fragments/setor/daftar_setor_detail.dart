import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'daftar_setor_nota.dart';

final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class SampahItem {
  String jenis;
  String berat;
  String harga;

  SampahItem({required this.jenis, required this.berat, required this.harga});

  factory SampahItem.fromJson(Map<String, dynamic> json) {
    final rawBerat = json['berat']?.toString() ?? '0';
    final rawHarga = json['harga']?.toString() ?? '0';
    return SampahItem(
      jenis: json['jenis'] ?? '-',
      berat: rawBerat,
      harga: rawHarga,
    );
  }

  Map<String, dynamic> toJson() => {
        'jenis': jenis,
        'berat': berat,
        'harga': harga,
      };
}

class SetorDetailView extends StatefulWidget {
  final String id;
  const SetorDetailView({Key? key, required this.id}) : super(key: key);

  @override
  State<SetorDetailView> createState() => _SetorDetailViewState();
}

class _SetorDetailViewState extends State<SetorDetailView> {
  final List<String> _statusOptions = [
    'Pending',
    'Pickup',
    'Arrived',
    'Diproses',
    'Selesai'
  ];
  String _selectedStatus = 'Pending';
  bool _isLoading = true;
  bool editMode = false;

  final Map<String, double> hargaPerGram = {
    'Aluminium': 10,
    'Gallon': 4.5,
    'Botol Kaca': 1.5,
    'Botol Plastik Tidak Berwarna': 6.1,
    'Botol Plastik Berwarna': 2.5,
    'Kardus': 1.8,
    'Plastik Kemasan': 0.5,
    'Tutup Botol': 3,
    'Sampah Organik': 1,
  };
  final List<String> jenisSampahList = [
    'Aluminium',
    'Gallon',
    'Botol Kaca',
    'Botol Plastik Tidak Berwarna',
    'Botol Plastik Berwarna',
    'Kardus',
    'Plastik Kemasan',
    'Tutup Botol',
    'Sampah Organik'
  ];

  String orderId = '-';
  String username = '-';
  String email = '-';
  String phone = '-';
  String alamat = '-';
  String waktu = '-';
  String catatan = '-';
  List<SampahItem> sampahItems = [];
  List<TextEditingController> beratControllers = [];

  int get _totalHarga =>
      sampahItems.fold(0, (sum, item) => sum + (int.tryParse(item.harga) ?? 0));

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  void updateHargaOtomatis(int index) {
    final jenis = sampahItems[index].jenis;
    final berat = double.tryParse(sampahItems[index].berat) ?? 0;
    final hargaGram = hargaPerGram[jenis] ?? 0;
    final total = (berat * hargaGram).round();
    sampahItems[index].harga = total.toString();
    setState(() {}); // update tampilan dan total harga
  }

  Future<void> _fetchDetail() async {
    final apiUrl = dotenv.env['API_URL'];
    final response =
        await http.get(Uri.parse('$apiUrl/api/setoran/${widget.id}'));

    print('📥 STATUS CODE: ${response.statusCode}');
    print('📦 RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ DECODED DATA: $data');
      if (!mounted) return;
      setState(() {
        orderId = data['order_id'] ?? '-';
        username = data['nama'] ?? '-';
        email = data['email'] ?? '-';
        phone = data['phone'] ?? '-';
        alamat = data['alamat'] ?? '-';
        waktu = data['tanggal'] != null
            ? DateFormat("dd MMMM yyyy, hh.mm a", "id_ID")
                .format(DateTime.parse(data['tanggal']).toLocal())
            : '-';
        catatan = data['catatan'] ?? '-';
        _selectedStatus = data['status'] ?? 'Pending';
        editMode = (_selectedStatus == 'Diproses');

        sampahItems = (data['sampah'] as List<dynamic>)
            .map((item) => SampahItem.fromJson(item))
            .toList();
        _isLoading = false;

        beratControllers = sampahItems.map((item) => TextEditingController(text: item.berat)).toList();
      });
    } else {
      print('Gagal ambil data detail: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetoran() async {
    final apiUrl = dotenv.env['API_URL'];

    // Hitung ulang total harga jika perlu
    int totalHarga = 0;
    for (final item in sampahItems) {
      totalHarga += int.tryParse(item.harga) ?? 0;
    }

    final response = await http.put(
      Uri.parse('$apiUrl/api/setoran/${widget.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': _selectedStatus,
        'sampah': sampahItems.map((e) => e.toJson()).toList(),
        'total_harga': totalHarga,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diupdate'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
      Navigator.pop(context, 'updated');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal update status!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _patchStatusSetoran() async {
    final apiUrl = dotenv.env['API_URL'];
    final response = await http.patch(
      Uri.parse('$apiUrl/api/setoran/${widget.id}/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': _selectedStatus}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status berhasil diubah'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
      Navigator.pop(context, 'updated');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal update status!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var c in beratControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditable = (_selectedStatus == 'Diproses') && editMode;
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
          'Detail Setoran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Tambahkan tombol untuk melihat nota
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetorNotaView(id: widget.id, isAdmin: true),
                ),
              );
            },
            tooltip: 'Lihat Nota',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Order ID',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  orderId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_selectedStatus)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(_selectedStatus),
                                    color: _getStatusColor(_selectedStatus),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedStatus,
                                    style: TextStyle(
                                      color: _getStatusColor(_selectedStatus),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Data Diri Section
                    _buildSectionCard(
                      title: 'Data Diri',
                      child: Column(
                        children: [
                          _buildInfoRow('Username', username),
                          _buildInfoRow('Email', email),
                          _buildInfoRow('Alamat', alamat, isMultiLine: true),
                          _buildInfoRow('Nomor Telepon', phone),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Keterangan Setor Sampah Section
                    _buildSectionCard(
                      title: 'Keterangan Setor Sampah',
                      child: Column(
                        children: [
                          _buildInfoRow('Waktu Order', waktu),
                          _buildInfoRow('Catatan', catatan),
                          _buildInfoRow('Alamat', alamat, isMultiLine: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sampah Items
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Jenis Sampah',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Berat',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Harga',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sampah Items List
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sampahItems.length,
                          itemBuilder: (context, index) {
                            final item = sampahItems[index];

                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12), // jarak antar baris
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Jenis Sampah
                                  Expanded(
                                    flex: 4,
                                    child: isEditable
                                        ? DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: jenisSampahList.contains(item.jenis) ? item.jenis : null,
                                            items: jenisSampahList
                                                .map((jenis) => DropdownMenuItem(
                                                      value: jenis,
                                                      child: Text(
                                                        jenis,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                item.jenis = val!;
                                                updateHargaOtomatis(index);
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              hintText: "Jenis Sampah",
                                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                              ),
                                              filled: true,
                                              fillColor: Color(0xFFE0F2F1),
                                              isDense: true,
                                            ),
                                          )
                                        : Text(
                                            item.jenis,
                                            style: const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Berat
                                  Expanded(
                                    flex: 2,
                                    child: isEditable
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: beratControllers[index],
                                                  onChanged: (val) {
                                                    item.berat = val;
                                                    updateHargaOtomatis(index);
                                                  },
                                                  keyboardType: TextInputType.number,
                                                  maxLines: 1,
                                                  textAlignVertical: TextAlignVertical.center,
                                                  style: const TextStyle(fontSize: 14),
                                                  decoration: const InputDecoration(
                                                    hintText: "Berat",
                                                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                                    ),
                                                    filled: true,
                                                    fillColor: Color(0xFFE0F2F1),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'g',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isEditable ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(item.berat, style: const TextStyle(fontSize: 14)),
                                              const SizedBox(width: 2),
                                              const Text('g', style: TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Harga
                                  Expanded(
                                    flex: 3,
                                    child: isEditable
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0E0E0),
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Rp ${item.harga}',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          )
                                        : Text(
                                            currencyFormat.format(int.tryParse(item.harga) ?? 0),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                  ),

                                ],
                              ),
                            );
                          },
                        ),

                        // Total
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFF26A69A),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                currencyFormat.format(_totalHarga),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF26A69A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Status Selection
                    Row(
                      children: [
                        const Text(
                          'Pilih Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                style: const TextStyle(color: Colors.black),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                                items: _statusOptions
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons row
                    Row(
                      children: [
                        // Lihat Nota Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedStatus == 'Selesai'
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SetorNotaView(id: widget.id),
                                      ),
                                    );
                                  }
                                : null, // tombol akan disabled kalau bukan "Selesai"
                            icon: const Icon(Icons.receipt_long, color: Colors.white),
                            label: const Text(
                              'Lihat Nota',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Submit Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (!editMode && _selectedStatus == 'Diproses') {
                                // Pertama kali status diproses: PATCH status & aktifkan edit mode
                                await _patchStatusSetoran();
                                setState(() {
                                  editMode = true;
                                });
                                await _fetchDetail();
                                return;
                              }
                              if (editMode && _selectedStatus == 'Diproses') {
                                // Sudah edit mode: update data (PUT)
                                await _updateSetoran();
                                setState(() {
                                  editMode = false;
                                });
                                await _fetchDetail();
                                return;
                              }
                              // Untuk status lain
                              await _patchStatusSetoran();
                              await _fetchDetail();
                            },
                            icon: const Icon(Icons.check_circle,
                                color: Colors.white),
                            label: const Text(
                              'SUBMIT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26A69A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF26A69A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Pickup':
        return Colors.blue;
      case 'Arrived':
        return Colors.purple;
      case 'Diproses':
        return Colors.amber;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule;
      case 'Pickup':
        return Icons.local_shipping;
      case 'Arrived':
        return Icons.place;
      case 'Diproses':
        return Icons.autorenew;
      case 'Selesai':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}
