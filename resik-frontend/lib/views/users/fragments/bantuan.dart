import 'package:flutter/material.dart';

class BantuanFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Panduan',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildGuideSection(
              'Pilih Jenis Sampah',
              [
                'Siapkan jenis sampah yang akan di scan',
                'Tentukan berat sampah',
                'Pilih setor sampah atau rekomendasi pengolahan'
              ],
            ),
            buildGuideSection(
              'Menambahkan gambar sampah',
              ['Siapkan gambar dari galeri atau kamera', 'Masukan maksimal 3 gambar'],
            ),
            buildGuideSection(
              'Masukan Informasi',
              [
                'Isi data informasi yang tersedia',
                'Konfirmasi tanggal waktu penjemputan'
                'Konfirmasi alamat penjemputan sampah pada catatan'
              ],
            ),
            buildGuideSection(
              'Pilih Metode Reward',
              [
                'Pilih metode reward yang tersedia',
                'Reward diberikan secara non-tunai',
                'Pastikan menerima pesan informasi setelah menerima reward'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGuideSection(String title, List<String> steps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            SizedBox(height: 12),
            Column(
              children: steps.map((step) => buildStepItem(step)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStepItem(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.radio_button_checked, color: Colors.teal, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              step,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
