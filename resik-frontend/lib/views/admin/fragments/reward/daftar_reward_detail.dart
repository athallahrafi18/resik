import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class RewardDetailView extends StatefulWidget {
  final String id;
  const RewardDetailView({Key? key, required this.id}) : super(key: key);

  @override
  State<RewardDetailView> createState() => _RewardDetailViewState();
}

class _RewardDetailViewState extends State<RewardDetailView> {
  final List<String> _statusOptions = ['Menunggu', 'Proses', 'Berhasil'];
  String _selectedStatus = 'Menunggu';
  bool _isLoading = true;

  String rewardId = '-';
  String namaUser = '-';
  String phone = '-';
  String metode = '-';
  String rekening = '-';
  String tanggalKlaim = '-';
  int nominal = 0;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final apiUrl = dotenv.env['API_URL'];
    final response =
        await http.get(Uri.parse('$apiUrl/api/rewards/${widget.id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        rewardId = data['reward_id'] ?? '-';
        namaUser = data['nama'] ?? '-';
        phone = data['phone'] ?? '-';
        metode = data['metode'] ?? '-';
        rekening = data['rekening'] ?? '-';
        nominal = data['nominal'] ?? 0;
        _selectedStatus = data['status'] ?? 'Menunggu';
        tanggalKlaim = data['created_at'] != null
            ? DateFormat('dd MMMM yyyy, HH.mm', 'id_ID')
                .format(DateTime.parse(data['created_at']).toLocal())
            : '-';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    final apiUrl = dotenv.env['API_URL'];

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/api/rewards/${widget.id}/status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'status': _selectedStatus}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status berhasil diperbarui'), backgroundColor: Color(0xFF26A69A),),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Detail Reward',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reward ID Card
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
                                  'Reward ID',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  rewardId,
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
                          _buildInfoRow('Nama', namaUser),
                          _buildInfoRow('Nomor Telepon', phone),
                          _buildInfoRow('Metode', metode),
                          _buildInfoRow('Nomor Rekening', rekening),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Keterangan Reward Section
                    _buildSectionCard(
                      title: 'Keterangan Reward',
                      child: Column(
                        children: [
                          _buildInfoRow('Reward ID', rewardId),
                          _buildInfoRow('Waktu Klaim', tanggalKlaim),
                          _buildInfoRow('Nominal', currencyFormat.format(nominal)),
                        ],
                      ),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                style:
                                    const TextStyle(color: Colors.black),
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
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _updateStatus,
                            icon: const Icon(Icons.check_circle, color: Colors.white),
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
      case 'Menunggu':
        return Colors.grey;
      case 'Proses':
        return Colors.amber;
      case 'Berhasil':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Menunggu':
        return Icons.schedule;
      case 'Proses':
        return Icons.autorenew;
      case 'Berhasil':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}
