import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class RewardFragment extends StatefulWidget {
  @override
  State<RewardFragment> createState() => _RewardFragmentState();
}

class _RewardFragmentState extends State<RewardFragment> {
  String saldo = '0';
  int saldoInt = 0;
  String? metode;
  bool isLoading = true;
  int berhasil = 0;
  int proses = 0;
  int menunggu = 0;

  late TextEditingController usernameController;
  late TextEditingController phoneController;
  late TextEditingController rekeningController;
  late TextEditingController nominalKlaimController;
  int? _nominalKlaimInt;
  String? _nominalError;

  final int minKlaim = 5000; // Contoh batas minimal klaim

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    phoneController = TextEditingController();
    rekeningController = TextEditingController();
    nominalKlaimController = TextEditingController();
    fetchRewardData();
    nominalKlaimController.addListener(_formatNominalKlaim);
  }

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    rekeningController.dispose();
    nominalKlaimController.dispose();
    super.dispose();
  }

  void _formatNominalKlaim() {
    String input = nominalKlaimController.text.replaceAll('.', '').replaceAll('Rp', '').replaceAll(',', '').trim();
    int value = int.tryParse(input) ?? 0;
    String formatted = _formatRupiah(value);

    if (nominalKlaimController.text != formatted) {
      nominalKlaimController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    _nominalKlaimInt = value;

    // Validasi error
    String? error;
    if (value > saldoInt) {
      error = 'Nominal klaim melebihi batas saldo';
    } else if (value < minKlaim && value > 0) {
      error = 'Minimal klaim adalah Rp. ${_formatRupiah(minKlaim)}';
    } else {
      error = null;
    }

    setState(() {
      _nominalError = error;
    });
  }

  Future<void> fetchRewardData() async {
    final apiUrl = dotenv.env['API_URL'];
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) return;

    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse('$apiUrl/api/reward/saldo'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final _saldoStr = data['saldo']?.toString() ?? '0';
      final _saldoInt = int.tryParse(_saldoStr) ?? 0;
      usernameController.text = data['username'] ?? '';
      phoneController.text = data['phone'] ?? '';
      setState(() {
        saldo = _saldoStr;
        saldoInt = _saldoInt;
        berhasil = data['countBerhasil'] ?? 0;
        proses = data['countProses'] ?? 0;
        menunggu = data['countMenunggu'] ?? 0;
        isLoading = false;
        _nominalKlaimInt = 0;
        nominalKlaimController.text = '';
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> claimReward() async {
    final apiUrl = dotenv.env['API_URL'];
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) return;

    final response = await http.post(
      Uri.parse('$apiUrl/api/reward/claim'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'nama': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
        'nominal': _nominalKlaimInt,
        'metode': metode,
        'rekening': rekeningController.text.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Berhasil klaim
      // TODO: Tambah navigation ke halaman sukses jika ada
      fetchRewardData();
      rekeningController.clear();
      nominalKlaimController.clear();
      setState(() {
        metode = null;
        _nominalKlaimInt = 0;
        _nominalError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil klaim reward!')),
      );
    } else {
      print('RESPONSE: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal klaim reward')),
      );
    }
  }

  String _formatRupiah(int angka) {
    if (angka == 0) return '0';
    String s = angka.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = s.replaceAllMapped(reg, (Match m) => "${m[1]}.");
    return result;
  }

  Widget buildRewardStatus(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal[900]),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Reward',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo dan Status Reward
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Rp. ${_formatRupiah(saldoInt)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              buildRewardStatus(berhasil.toString(), 'Berhasil'),
                              buildRewardStatus(proses.toString(), 'Proses'),
                              buildRewardStatus(menunggu.toString(), 'Menunggu'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    buildTextField('Nama :', controller: usernameController),
                    buildTextField('Nomor Telepon :', controller: phoneController, keyboardType: TextInputType.phone),
                    // Nominal Klaim (format rupiah & validasi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nominalKlaimController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Nominal Klaim :',
                              prefixText: 'Rp. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_nominalError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                              child: Text(
                                _nominalError!,
                                style: TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Dropdown Metode (dengan placeholder)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: metode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Pilih Metode', style: TextStyle(color: Colors.grey)),
                            enabled: true,
                          ),
                          DropdownMenuItem<String>(
                            value: 'Bank BNI',
                            child: Text('Bank BNI'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'E-Wallet Dana',
                            child: Text('E-Wallet Dana'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            metode = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih metode terlebih dahulu';
                          }
                          return null;
                        },
                      ),
                    ),
                    buildTextField('Nomor Rekening :',
                        controller: rekeningController, keyboardType: TextInputType.number),
                    SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: (saldoInt > 0 &&
                                rekeningController.text.isNotEmpty &&
                                usernameController.text.isNotEmpty &&
                                phoneController.text.isNotEmpty &&
                                _nominalKlaimInt != null &&
                                _nominalKlaimInt! >= minKlaim &&
                                _nominalKlaimInt! <= saldoInt &&
                                metode != null &&
                                !isLoading)
                            ? claimReward
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'KLAIM REWARD',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTextField(String label,
      {bool isReadOnly = false,
      String? initialValue,
      TextEditingController? controller,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller ??
            (initialValue != null
                ? TextEditingController(text: initialValue)
                : null),
        readOnly: isReadOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
