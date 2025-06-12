import 'package:flutter/material.dart';

class PanduanFragment extends StatelessWidget {
  const PanduanFragment({Key? key}) : super(key: key);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStepCard(
              stepNumber: 1,
              title: 'Pilih Jenis Sampah',
              instructions: [
                'Siapkan sampah yang akan di setor',
                'Tentukan berat sampah',
                'Pilih setor sampah atau rekomendasi pengolahan',
              ],
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              stepNumber: 2,
              title: 'Menambahkan gambar sampah',
              instructions: [
                'Siapkan gambar dari galeri atau kamera',
                'Masukan gambar yang akan di scan',
              ],
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              stepNumber: 3,
              title: 'Masukan Informasi',
              instructions: [
                'Isi data informasi yang tersedia',
                'Konfirmasi waktu penjemputan',
                'Konfirmasi alamat penjemputan sampah pada catatan',
              ],
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              stepNumber: 4,
              title: 'Pilih Metode Reward',
              instructions: [
                'Pilih metode reward yang tersedia',
                'Reward diberikan secara non-tunai',
                'Pastikan menerima pesan notifikasi setelah menerima reward',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required List<String> instructions,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: instructions.map((instruction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          instruction,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
