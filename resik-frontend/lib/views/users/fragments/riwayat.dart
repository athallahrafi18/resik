import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class TransactionHistory {
  final String id;
  final DateTime date;
  final String type; // "masuk" atau "keluar"
  final String description;
  final int amount;

  TransactionHistory({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    // Lebih aman handle null dan parse error
    int amountVal = 0;
    if (json['amount'] is int) {
      amountVal = json['amount'] ?? 0;
    } else if (json['amount'] is String) {
      amountVal = int.tryParse(json['amount']) ?? 0;
    }
    DateTime dt;
    try {
      dt = DateTime.parse(json['created_at']);
    } catch (_) {
      dt = DateTime.now();
    }
    return TransactionHistory(
      id: json['id'] ?? '',
      date: dt,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      amount: amountVal,
    );
  }
}

Future<List<TransactionHistory>> fetchTransactionHistory(String userId) async {
  final apiUrl = dotenv.env['API_URL'];
  final url = '$apiUrl/api/reward-history/$userId';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => TransactionHistory.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data riwayat');
    }
  } catch (e) {
    throw Exception('Terjadi error jaringan: $e');
  }
}

class RiwayatFragment extends StatefulWidget {
  final String userId;
  const RiwayatFragment({Key? key, required this.userId}) : super(key: key);

  @override
  State<RiwayatFragment> createState() => _RiwayatFragmentState();
}

class _RiwayatFragmentState extends State<RiwayatFragment> {
  late Future<List<TransactionHistory>> futureTransactions;

  @override
  void initState() {
    super.initState();
    futureTransactions = fetchTransactionHistory(widget.userId);
  }

  // Group transactions by date
  Map<String, List<TransactionHistory>> groupTransactionsByDate(List<TransactionHistory> txs) {
    Map<String, List<TransactionHistory>> grouped = {};
    DateTime now = DateTime.now();
    for (var tx in txs) {
      String label;
      if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
        label = 'Hari Ini';
      } else {
        label = DateFormat('EEEE, d MMMM y', 'id_ID').format(tx.date);
      }
      grouped[label] = grouped[label] ?? [];
      grouped[label]!.add(tx);
    }
    // urutkan Hari Ini dulu, lalu tanggal desc
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Hari Ini') return -1;
        if (b == 'Hari Ini') return 1;
        DateTime getDate(String key) => key == 'Hari Ini' ? now : DateFormat('EEEE, d MMMM y', 'id_ID').parse(key);
        return getDate(b).compareTo(getDate(a));
      });
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  String formatCurrency(int amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          'Riwayat',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<TransactionHistory>>(
        future: futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat data riwayat"));
          }
          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/empty.png', height: 150),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }

          final grouped = groupTransactionsByDate(transactions);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final group in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Text(
                    group.key,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                ...group.value.map((tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: tx.type == "masuk" ? Colors.green[50] : Colors.red[50],
                            child: Icon(
                              tx.type == "masuk" ? Icons.check_circle : Icons.arrow_upward,
                              color: tx.type == "masuk" ? Colors.green : Colors.red,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            tx.description,
                            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 16),
                          ),
                          subtitle: tx.type == "masuk"
                              ? const Text("Reward Masuk", style: TextStyle(color: Colors.green))
                              : const Text("Penarikan Reward", style: TextStyle(color: Colors.red)),
                          trailing: Text(
                            (tx.type == "masuk" ? "+ " : "- ") + formatCurrency(tx.amount),
                            style: TextStyle(
                              color: tx.type == "masuk" ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
