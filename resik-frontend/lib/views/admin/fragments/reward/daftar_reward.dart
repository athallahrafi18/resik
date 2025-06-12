import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'daftar_reward_detail.dart';

class RewardModel {
  final String id;
  final String rewardId;
  final String namaUser;
  final int nominal;
  final String status;
  final String tanggalReward;

  RewardModel({
    required this.id,
    required this.rewardId,
    required this.namaUser,
    required this.nominal,
    required this.status,
    required this.tanggalReward,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] ?? '',
      rewardId: json['reward_id'] ?? '',
      namaUser: json['nama_user'] ?? '',
      nominal: json['nominal'] ?? 0,
      status: json['status'] ?? 'Pending',
      tanggalReward: json['tanggal_reward'] != null
          ? DateFormat('dd MMM yyyy', 'id_ID')
              .format(DateTime.parse(json['tanggal_reward']).toLocal())
          : '',
    );
  }
}


class DaftarRewardFragment extends StatefulWidget {
  const DaftarRewardFragment({Key? key}) : super(key: key);

  @override
  State<DaftarRewardFragment> createState() => _DaftarRewardFragmentState();
}

class _DaftarRewardFragmentState extends State<DaftarRewardFragment> {
  final List<String> _statusOptions = [
    'Semua',
    'Menunggu',
    'Proses',
    'Berhasil',
  ];
  String _selectedStatus = 'Semua';

  List<RewardModel> _rewardList = [];

  @override
  void initState() {
    super.initState();
    _initializeLocaleAndFetchData();
  }

  Future<void> _initializeLocaleAndFetchData() async {
    await initializeDateFormatting('id_ID', null);
    await _fetchRewardData();
  }

  Future<void> _fetchRewardData() async {
    try {
      final apiUrl = dotenv.env['API_URL'];
      final queryParam =
          _selectedStatus != 'Semua' ? '?status=$_selectedStatus' : '';

      final response = await http.get(
        Uri.parse('$apiUrl/api/rewards$queryParam'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<RewardModel> loadedRewards =
            data.map((jsonItem) => RewardModel.fromJson(jsonItem)).toList();

        setState(() {
          _rewardList = loadedRewards;
        });
      } else {
        print('Gagal ambil data reward: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error saat ambil data reward: $e');
    }
  }

  List<RewardModel> get _filteredList => _rewardList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF26A69A),
            padding: const EdgeInsets.only(top: 40, bottom: 15, left: 15, right: 15),
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
                  // Title & Dropdown filter
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Reward',
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
                            icon: const Icon(Icons.filter_list, color: Color(0xFF26A69A)),
                            style: const TextStyle(color: Color(0xFF26A69A)),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                                _fetchRewardData();
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

                  // Tombol Export (opsional, bisa kamu aktifkan)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  ),

                  // Daftar reward
                  Expanded(
                    child: _filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada data reward',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredList.length,
                            itemBuilder: (context, index) {
                              final reward = _filteredList[index];
                              return _buildRewardItem(reward);
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

  Widget _buildRewardItem(RewardModel reward) {
    Color statusColor;
    IconData statusIcon;

    switch (reward.status) {
      case 'Menunggu':
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
      case 'Proses':
        statusColor = Colors.amber;
        statusIcon = Icons.autorenew;
        break;
      case 'Berhasil':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RewardDetailView(id: reward.id),
          ),
        );
        if (result == true) {
          await _fetchRewardData();
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
              reward.id.length >= 3
                  ? reward.rewardId.substring(reward.rewardId.length - 3)
                  : reward.id,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            reward.namaUser,
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
                    reward.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'Reward ID: ${reward.rewardId} • ${reward.tanggalReward}',
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
                    builder: (context) => RewardDetailView(id: reward.id),
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
