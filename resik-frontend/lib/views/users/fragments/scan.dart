import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'setor_success.dart';
import 'pengolahan.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'barcode_scanner_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resik/views/users/dashboard_view.dart';
import 'live_scan_page.dart';

class ScanFragment extends StatefulWidget {
  const ScanFragment({Key? key}) : super(key: key);
  
  @override
  _ScanFragmentState createState() => _ScanFragmentState();
}

class _ScanFragmentState extends State<ScanFragment> {
  int totalHarga = 0;
  CameraController? _cameraController;
  String? hasilDeteksi;
  File? _lastPreviewImage;
  final FlutterVision vision = FlutterVision();
  TextEditingController namaController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController tanggalController = TextEditingController();
  TextEditingController catatanController = TextEditingController();
  TextEditingController beratController1 = TextEditingController();
  TextEditingController hargaController1 = TextEditingController();
  TextEditingController beratController2 = TextEditingController();
  TextEditingController hargaController2 = TextEditingController();
  TextEditingController beratController3 = TextEditingController();
  TextEditingController hargaController3 = TextEditingController();
  TextEditingController beratController4 = TextEditingController();
  TextEditingController hargaController4 = TextEditingController();
  TextEditingController beratController5 = TextEditingController();
  TextEditingController hargaController5 = TextEditingController();
  TextEditingController beratController6 = TextEditingController();
  TextEditingController hargaController6 = TextEditingController();
  TextEditingController beratController7 = TextEditingController();
  TextEditingController hargaController7 = TextEditingController();
  TextEditingController beratController8 = TextEditingController();
  TextEditingController hargaController8 = TextEditingController();
  String? jenisSampah1;
  String? jenisSampah2;
  String? jenisSampah3;
  String? jenisSampah4;
  String? jenisSampah5;
  String? jenisSampah6;
  String? jenisSampah7;
  String? jenisSampah8;
  final List<String> jenisSampahList = [
    'Botol Plastik Berwarna',
    'Botol Plastik Tidak Berwarna',
    'Kardus',
    'Aluminium',
    'Botol Kaca',
    'Gallon',
    'Tutup Botol',
    'Sampah Organik',
    'Plastik Kemasan'
  ];

  final Map<String, double> hargaPerGram = {
    'Botol Plastik Berwarna': 2.5,
    'Botol Plastik Tidak Berwarna': 6.1,
    'Kardus': 1.8,
    'Aluminium': 10,
    'Botol Kaca': 1.5,
    'Gallon': 4.5,
    'Tutup Botol': 3,
    'Sampah Organik': 1,
    'Plastik Kemasan': 0.5,
  };

  String? jenisHasilBarcode;
  String? beratHasilBarcode;

  void updateHargaOtomatis(TextEditingController beratController, TextEditingController hargaController, String? jenis) {
    final berat = double.tryParse(beratController.text) ?? 0;
    final hargaGram = hargaPerGram[jenis ?? ''] ?? 0;
    final total = (berat * hargaGram).round();
    hargaController.text = total.toString();
    hitungTotalHarga();
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/model.tflite',
      modelVersion: 'yolov8',
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }

  Future<ui.Image> decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _lastPreviewImage = File(pickedFile.path);
      });

      try {
        Uint8List bytes = await File(pickedFile.path).readAsBytes();
        final decodedImage = await decodeImage(bytes);

        final result = await vision.yoloOnImage(
          bytesList: bytes,
          imageHeight: decodedImage.height,
          imageWidth: decodedImage.width,
        );

        debugPrint("Hasil deteksi: $result");

        setState(() {
          if (result.isNotEmpty) {
            hasilDeteksi = result.map((res) {
              final tag = res['tag'];
              final box = res['box'];
              final score = (box != null && box.length >= 5)
                  ? (box[4] as num).toDouble()
                  : 0.0;

              return '$tag (${(score * 100).toStringAsFixed(2)}%)';
            }).join(', ');
          } else {
            hasilDeteksi = 'Tidak terdeteksi';
          }
        });
      } catch (e) {
        debugPrint("Terjadi error saat deteksi galeri: $e");
        setState(() {
          hasilDeteksi = 'Gagal mendeteksi';
        });
      }
    }
  }

  Future<void> submitData() async {
    final apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null) {
      print("API_URL belum diatur di .env");
      return;
    }

    final url = Uri.parse('$apiUrl/api/setor');

    // Ambil ID Token dari Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken == null) {
      print("Gagal mendapatkan token pengguna.");
      return;
    }

    // Buat list data sampah yang valid (tidak null/kosong)
    final sampahList = [
      {'jenis': jenisSampah1, 'berat': beratController1.text, 'harga': hargaController1.text},
      {'jenis': jenisSampah2, 'berat': beratController2.text, 'harga': hargaController2.text},
      {'jenis': jenisSampah3, 'berat': beratController3.text, 'harga': hargaController3.text},
      {'jenis': jenisSampah4, 'berat': beratController4.text, 'harga': hargaController4.text},
      {'jenis': jenisSampah5, 'berat': beratController5.text, 'harga': hargaController5.text},
      {'jenis': jenisSampah6, 'berat': beratController6.text, 'harga': hargaController6.text},
      {'jenis': jenisSampah7, 'berat': beratController7.text, 'harga': hargaController7.text},
      {'jenis': jenisSampah8, 'berat': beratController8.text, 'harga': hargaController8.text},
    ].where((item) =>
      item['jenis'] != null &&
      item['jenis'].toString().trim().isNotEmpty &&
      item['berat'].toString().trim().isNotEmpty &&
      item['harga'].toString().trim().isNotEmpty
    ).toList();

    // Validasi sebelum submit
    if (namaController.text.trim().isEmpty || sampahList.isEmpty) {
      print("Data tidak lengkap. Nama dan minimal 1 sampah harus diisi.");
      return;
    }

    final data = {
      'nama': namaController.text.trim(),
      'alamat': alamatController.text.trim(),
      'tanggal': tanggalController.text.trim(),
      'catatan': catatanController.text.trim(),
      'total_harga': totalHarga,
      'sampah': sampahList,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // ← Tambahkan ini
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        print("Data berhasil dikirim.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SetorSuccessFragment()),
        );
      } else {
        print("Gagal mengirim data: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      print("Terjadi kesalahan: $e");
    }
  }

  void resetForm() {
    setState(() {
      totalHarga = 0;
      namaController.clear();
      alamatController.clear();
      tanggalController.clear();
      catatanController.clear();
      beratController1.clear();
      hargaController1.clear();
      beratController2.clear();
      hargaController2.clear();
      beratController3.clear();
      hargaController3.clear();
      beratController4.clear();
      hargaController4.clear();
      beratController5.clear();
      hargaController5.clear();
      beratController6.clear();
      hargaController6.clear();
      beratController7.clear();
      hargaController7.clear();
      beratController8.clear();
      hargaController8.clear();
      jenisSampah1 = null;
      jenisSampah2 = null;
      jenisSampah3 = null;
      jenisSampah4 = null;
      jenisSampah5 = null;
      jenisSampah6 = null;
      jenisSampah7 = null;
      jenisSampah8 = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    namaController.dispose();
    alamatController.dispose();
    tanggalController.dispose();
    catatanController.dispose();
    beratController1.dispose();
    hargaController1.dispose();
    beratController2.dispose();
    hargaController2.dispose();
    beratController3.dispose();
    hargaController3.dispose();
    beratController4.dispose();
    hargaController4.dispose();
    beratController5.dispose();
    hargaController5.dispose();
    beratController6.dispose();
    hargaController6.dispose();
    beratController7.dispose();
    hargaController7.dispose();
    beratController8.dispose();
    hargaController8.dispose();
    super.dispose();
  }

  void hitungTotalHarga() {
    setState(() {
      totalHarga = 0;

      final List<TextEditingController> hargaControllers = [
        hargaController1,
        hargaController2,
        hargaController3,
        hargaController4,
        hargaController5,
        hargaController6,
        hargaController7,
        hargaController8,
      ];

      for (final controller in hargaControllers) {
        final value = int.tryParse(controller.text) ?? 0;
        totalHarga += value;
      }
    });
  }

  // Fungsi mapping jenis dari backend ke dropdown
  String? mapJenisKeDropdown(String? jenis) {
    final mapping = {
      'aluminium': 'Aluminium',
      'botol plastik berwarna': 'Botol Plastik Berwarna',
      'botol plastik tidak berwarna': 'Botol Plastik Tidak Berwarna',
      'kardus': 'Kardus',
      'botol kaca': 'Botol Kaca',
      'gallon': 'Gallon',
      'tutup botol': 'Tutup Botol',
      'sampah organik': 'Sampah Organik',
      'plastik kemasan': 'Plastik Kemasan',
    };

    return mapping[jenis?.toLowerCase() ?? ''];
  }

  Future<void> kirimBarcodeKeBackend(String barcode) async {
    final apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null) {
      print('Error: API_URL tidak ditemukan di .env');
      return;
    }

    final url = Uri.parse('$apiUrl/api/barcode');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'barcode': barcode});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jenis = mapJenisKeDropdown(data['jenis']);
        final berat = data['berat'] ?? 0;
        final hargaPerGram = data['harga_per_gram'] ?? 0;
        final totalHarga = (berat * hargaPerGram).round();

        if (jenis == null || !jenisSampahList.contains(jenis)) {
          print('Jenis sampah tidak cocok: ${data['jenis']}');
          return;
        }

        setState(() {
          // ✅ Tampilkan di bagian Hasil Pindai
          hasilDeteksi = null;
          jenisHasilBarcode = jenis;
          beratHasilBarcode = berat.toString();

          // ✅ Isi slot kosong pertama
          for (int i = 0; i < 8; i++) {
            switch (i) {
              case 0:
                if (jenisSampah1 == null) {
                  jenisSampah1 = jenis;
                  beratController1.text = berat.toString();
                  hargaController1.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 1:
                if (jenisSampah2 == null) {
                  jenisSampah2 = jenis;
                  beratController2.text = berat.toString();
                  hargaController2.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 2:
                if (jenisSampah3 == null) {
                  jenisSampah3 = jenis;
                  beratController3.text = berat.toString();
                  hargaController3.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 3:
                if (jenisSampah4 == null) {
                  jenisSampah4 = jenis;
                  beratController4.text = berat.toString();
                  hargaController4.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 4:
                if (jenisSampah5 == null) {
                  jenisSampah5 = jenis;
                  beratController5.text = berat.toString();
                  hargaController5.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 5:
                if (jenisSampah6 == null) {
                  jenisSampah6 = jenis;
                  beratController6.text = berat.toString();
                  hargaController6.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 6:
                if (jenisSampah7 == null) {
                  jenisSampah7 = jenis;
                  beratController7.text = berat.toString();
                  hargaController7.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
              case 7:
                if (jenisSampah8 == null) {
                  jenisSampah8 = jenis;
                  beratController8.text = berat.toString();
                  hargaController8.text = totalHarga.toString();
                  hitungTotalHarga();
                  return;
                }
                break;
            }
          }
        });
      } else {
        print('Gagal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error kirim barcode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Setor Sampah',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardView(initialTab: 0)),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pindai sampah :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _lastPreviewImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<ui.Image>(
                      future: _lastPreviewImage!.readAsBytes().then((bytes) => decodeImage(bytes)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          final img = snapshot.data!;
                          return SizedBox(
                            width: img.width.toDouble(),
                            height: img.height.toDouble(),
                            child: Image.file(
                              _lastPreviewImage!,
                              fit: BoxFit.contain,
                            ),
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      'Belum ada gambar',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final btn in [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'SCAN SAMPAH',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LiveScanPage()),
                      );

                      if (result != null) {
                        final File rotatedImage = result['file'];
                        final List<dynamic> hasil = result['result'];

                        setState(() {
                          _lastPreviewImage = rotatedImage;
                          jenisHasilBarcode = null;
                          beratHasilBarcode = null;
                          hasilDeteksi = hasil.map((res) {
                            final tag = res['tag'];
                            final box = res['box'];
                            final score = (box != null && box.length >= 5)
                                ? (box[4] as num).toDouble()
                                : 0.0;
                            return '$tag (${(score * 100).toStringAsFixed(2)}%)';
                          }).join(', ');
                        });
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.upload_file,
                    label: 'UNGGAH GAMBAR',
                    onPressed: pickImageFromGallery,
                  ),
                  _buildActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'SCAN BARCODE',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BarcodeScannerPage()),
                      );
                      if (result != null) {
                        await kirimBarcodeKeBackend(result.toString());
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.delete_forever,
                    label: 'RESET GAMBAR',
                    onPressed: () {
                      setState(() {
                        _lastPreviewImage = null;
                        hasilDeteksi = null;
                        jenisHasilBarcode = null;
                        beratHasilBarcode = null;
                      });
                    },
                    color: Colors.redAccent,
                  ),
                ])
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 48) / 2, // 2 tombol per baris
                    child: btn,
                  ),
              ],
            ),
            SizedBox(height: 16),
            Divider(thickness: 1),
            SizedBox(height: 8),
            Text('Hasil Pindai :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasilDeteksi != null && hasilDeteksi != 'Tidak terdeteksi' && hasilDeteksi != 'Gagal mendeteksi')
                      Text(
                        hasilDeteksi!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                        textAlign: TextAlign.center,
                      )
                    else if (jenisHasilBarcode != null || beratHasilBarcode != null) ...[
                      Text(
                        'Jenis Sampah: $jenisHasilBarcode',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Berat: $beratHasilBarcode gram',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ]
                    else
                      Text(
                        'Data hasil pindai akan muncul di sini',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PengolahanFragment()),
                  );
                },
                child: Text('REKOMENDASI PENGOLAHAN',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 16),
            buildTextField('Nama :', namaController),
            SizedBox(height: 16),
            buildTextField('Alamat :', alamatController),
            SizedBox(height: 16),
            buildDatePickerField('Tanggal :', tanggalController),
            SizedBox(height: 16),
            buildTextField('Catatan :', catatanController),
            SizedBox(height: 16),
            Text('Jenis Sampah :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah1,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah1 = value;
                        updateHargaOtomatis(beratController1, hargaController1, jenisSampah1);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController1, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController1, hargaController1, jenisSampah1),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController1, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah2,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah2 = value;
                        updateHargaOtomatis(beratController2, hargaController2, jenisSampah2);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController2, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController2, hargaController2, jenisSampah2),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController2, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah3 = value;
                        updateHargaOtomatis(beratController3, hargaController3, jenisSampah3);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController3, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController3, hargaController3, jenisSampah3),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController3, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah4 = value;
                        updateHargaOtomatis(beratController4, hargaController4, jenisSampah4);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController4, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController4, hargaController4, jenisSampah4),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController4, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah5 = value;
                        updateHargaOtomatis(beratController5, hargaController5, jenisSampah5);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController5, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController5, hargaController5, jenisSampah5),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController5, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah6,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah6 = value;
                        updateHargaOtomatis(beratController6, hargaController6, jenisSampah6);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController6, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController6, hargaController6, jenisSampah6),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController6, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah7,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah7 = value;
                        updateHargaOtomatis(beratController7, hargaController7, jenisSampah7);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController7, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController7, hargaController7, jenisSampah7),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController7, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: jenisSampah8,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: Text('Pilih Jenis Sampah'),
                    items: jenisSampahList.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        jenisSampah8 = value;
                        updateHargaOtomatis(beratController8, hargaController8, jenisSampah8);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', beratController8, hint: 'Berat', onChanged: (_) => updateHargaOtomatis(beratController8, hargaController8, jenisSampah8),),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: buildTextField('', hargaController8, hint: 'Harga', onChanged: (_) => hitungTotalHarga(), readOnly: true,),
                ),
              ],
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: resetForm,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'BUANG RIWAYAT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total :',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                      'Rp. ${NumberFormat("#,###", "id_ID").format(totalHarga)}',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'SETOR SAMPAH',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {String? hint, void Function(String)? onChanged, bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged, // ✅ Panggil fungsi saat ada perubahan
    );
  }

  Widget buildDatePickerField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = pickedDate.toLocal().toString().split(' ')[0];
          });
        }
      },
    );
  }
}

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.teal, // default warna hijau
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: 12, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size(140, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
