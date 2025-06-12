import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationFragment extends StatefulWidget {
  const LocationFragment({super.key});

  @override
  State<LocationFragment> createState() => _LocationFragmentState();
}

class _LocationFragmentState extends State<LocationFragment> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> lokasiList = const [
    {
      'id': 1,
      'image': 'assets/images/lokasi1.png',
      'alamat': 'Bandung, Jl. Terusan Bojongsoang No.174A, Kec. Baleendah, Kabupaten Bandung, Jawa Barat 40375',
      'telp': '0813-3331-8856',
      'jam': 'Senin-Jumat\n08.00 - 16.00\nSabtu\n08.00 - 14.00',
      'mapsQuery': 'Bank Sampah Bersinar'
    },
    {
      'id': 2,
      'image': 'assets/images/lokasi2.png',
      'alamat': 'Jl. Sadang Tengah No.6, Sekeloa, Kecamatan Coblong, Kota Bandung, Jawa Barat 40133',
      'telp': '-',
      'jam': 'Senin - Sabtu\n08.00 - 16.30',
      'mapsQuery': 'Bank Sampah Induk Cabang Sadang Serang'
    },
    {
      'id': 3,
      'image': 'assets/images/lokasi3.png',
      'alamat': 'Jl. Kyai H. Usman Dhomiri No.15, Padasuka, Kec. Cimahi Tengah, Kota Cimahi, Jawa Barat 40526',
      'telp': '(022) 6641047',
      'jam': 'Senin - Sabtu\n08.00 - 16.00',
      'mapsQuery': 'Bank Sampah Induk Cimahi'
    },
    {
      'id': 4,
      'image': 'assets/images/lokasi4.png',
      'alamat': 'Jl. Lintas Balige - Siantar, desa Tambunan, Lumban Pea Tim.',
      'telp': '-',
      'jam': 'Senin - Sabtu\n08.00 - 16.00',
      'mapsQuery': 'Bank Sampah Induk Tarhilala'
    },
  ];

  Future<void> _openMaps(String query) async {
    setState(() => _isLoading = true);

    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Tidak dapat membuka Google Maps');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text(
              'Lokasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lokasiList.length,
            itemBuilder: (context, index) {
              final lokasi = lokasiList[index];
              return Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _isLoading ? null : () => _openMaps(lokasi['mapsQuery']),
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.teal.withOpacity(0.2),
                      child: Container(
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: -110,
                              right: 100,
                                child: Image.asset(
                                  lokasi['image'],
                                  width: 350,
                                  height: 350,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Text('Gambar\ntidak ada', textAlign: TextAlign.center),
                                ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 140),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 20, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          lokasi['alamat'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.justify,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 20, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        lokasi['telp'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          lokasi['jam'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 42,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${lokasi['id']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // loading overlay
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
