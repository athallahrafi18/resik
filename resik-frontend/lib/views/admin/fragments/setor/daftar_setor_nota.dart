import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SampahItem {
  final String jenis;
  final String berat;
  final String harga;

  SampahItem({required this.jenis, required this.berat, required this.harga});

  factory SampahItem.fromJson(Map<String, dynamic> json) {
    return SampahItem(
      jenis: json['jenis'] ?? '-',
      berat: json['berat'] ?? '0',
      harga: json['harga']?.toString() ?? '0',
    );
  }
}

class SetorNotaView extends StatefulWidget {
  final String id;
  final bool isAdmin;
  const SetorNotaView({Key? key, required this.id, this.isAdmin = false}) : super(key: key);

  @override
  State<SetorNotaView> createState() => _SetorNotaViewState();
}

class _SetorNotaViewState extends State<SetorNotaView> {
  bool _isLoading = true;
  String orderId = '-';
  String userName = '-';
  String alamat = '-';
  String invoiceDate = '-';
  String phone = '-';
  List<SampahItem> sampahItems = [];
  int totalHarga = 0;

  String formatPhone(String raw) {
    String phone = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.startsWith('0')) {
      phone = '62' + phone.substring(1);
    }
    return phone;
  }

  @override
  void initState() {
    super.initState();
    _fetchNotaDetail();
  }

  Future<void> _fetchNotaDetail() async {
    final apiUrl = dotenv.env['API_URL'];
    final response = await http.get(Uri.parse('$apiUrl/api/setoran/${widget.id}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Total harga
      int total = 0;
      List<SampahItem> items = [];
      if (data['sampah'] != null) {
        items = (data['sampah'] as List)
            .map((item) => SampahItem.fromJson(item))
            .toList();
        total = items.fold(0, (sum, item) => sum + (int.tryParse(item.harga) ?? 0));
      }

      setState(() {
        orderId = data['order_id'] ?? '-';
        userName = data['nama'] ?? '-';
        alamat = data['alamat'] ?? '-';
        invoiceDate = data['tanggal'] != null
            ? DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(data['tanggal']).toLocal())
            : '-';
        sampahItems = items;
        totalHarga = total;
        phone = data['phone'] ?? '-';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void shareToWhatsApp() async {
    final nomor = formatPhone(phone);

    // Format daftar sampah
    final itemList = sampahItems.map((item) {
      // Format berat (misal kamu mau tampil "1 Kg" kalau berat >= 1000, atau "14g" kalau < 1000)
      String beratText;
      int beratInt = int.tryParse(item.berat) ?? 0;
      if (beratInt >= 1000) {
        double beratKg = beratInt / 1000;
        beratText = "${beratKg.toStringAsFixed(2)} Kg";
      } else {
        beratText = "${item.berat}g";
      }

      // Format harga
      String hargaText = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(int.tryParse(item.harga) ?? 0);

      return "- ${item.jenis} ($beratText) $hargaText";
    }).join('\n');

    // Format total harga
    String totalText = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(totalHarga);

    // Build message
    final pesan = Uri.encodeComponent(
      'Halo $userName!\n\n'
      'Berikut nota setor sampahmu di Resik:\n'
      'Order ID: $orderId\n'
      'Tanggal: $invoiceDate\n\n'
      'Detail Sampah:\n'
      '$itemList\n\n'
      'Total: $totalText\n\n'
      'Detail sampah yang diberikan sudah merupakan hasil evaluasi oleh pihak Bank Sampah Bersinar.\n\n'
      'Terima kasih sudah menyetorkan sampahmu! ♻️'
    );

    final url = 'https://wa.me/$nomor?text=$pesan';

    await Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Membuka WhatsApp...'), backgroundColor: Color(0xFF26A69A)),
    );
    await Future.delayed(const Duration(milliseconds: 400));
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka WhatsApp')),
      );
    }
  }

  Future<void> _downloadNotaAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('NOTA SETOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.Text('Order ID: $orderId'),
              pw.Text('Tanggal: $invoiceDate'),
              pw.Text('Nama: $userName'),
              pw.Text('Alamat: $alamat'),
              pw.SizedBox(height: 10),

              pw.Text('-- Detail Sampah (Hasil Evaluasi Bank Sampah Bersinar) --', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
              pw.SizedBox(height: 6),

              // HEADER TABEL
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Jenis Sampah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Center(
                      child: pw.Text('Berat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              pw.Divider(),

              // List detail sampah
              ...sampahItems.map((item) => pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(item.jenis),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Center(
                      child: pw.Text('${item.berat} g'),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                            .format(int.tryParse(item.harga) ?? 0),
                      ),
                    ),
                  ),
                ],
              )),

              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalHarga),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Terima kasih sudah menyetorkan sampahmu!', style: pw.TextStyle(color: PdfColors.teal, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    // Preview dan download PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<File> generateNotaPdfFile() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('NOTA SETOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.Text('Order ID: $orderId'),
              pw.Text('Tanggal: $invoiceDate'),
              pw.Text('Nama: $userName'),
              pw.Text('Alamat: $alamat'),
              pw.SizedBox(height: 10),
              pw.Text('-- Detail Sampah (Hasil Evaluasi Bank Sampah Bersinar) --', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Jenis Sampah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Center(
                      child: pw.Text('Berat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              ...sampahItems.map((item) => pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(item.jenis)),
                  pw.Expanded(flex: 2, child: pw.Center(child: pw.Text('${item.berat} g'))),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                            .format(int.tryParse(item.harga) ?? 0),
                      ),
                    ),
                  ),
                ],
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalHarga),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Terima kasih sudah menyetorkan sampahmu!', style: pw.TextStyle(color: PdfColors.teal, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/nota-setor-$orderId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
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
          'Nota Setor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _isLoading
                ? null
                : () async {
                    final pdfFile = await generateNotaPdfFile();
                    await Share.shareXFiles(
                      [XFile(pdfFile.path)],
                      text: 'Berikut terlampir nota setor sampahmu dari Resik.',
                      subject: 'Nota Setor Sampah',
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: _isLoading ? null : _downloadNotaAsPdf,
            tooltip: 'Cetak Nota',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header Card (NOTA, order, user)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'NOTA',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF26A69A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.recycling,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Resik',
                                      style: TextStyle(
                                        color: Color(0xFF26A69A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nota Pesanan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Bank Sampah Bersinar',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF2196F3),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        alamat,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '#$orderId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Invoice date',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        invoiceDate,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No Order #',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '#$orderId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Table sampah
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: const [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Jenis Sampah',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Berat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Harga',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 8),
                            ...sampahItems.map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(item.jenis),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('${item.berat} g',
                                            textAlign: TextAlign.center),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          NumberFormat.currency(
                                                  locale: 'id_ID',
                                                  symbol: 'Rp ',
                                                  decimalDigits: 0)
                                              .format(
                                                  int.tryParse(item.harga) ?? 0),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            // Kosongkan sisa baris kalau kurang dari 5 item (biar tetap rapi)
                            for (int i = 0; i < (5 - sampahItems.length); i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
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
                                  NumberFormat.currency(
                                          locale: 'id_ID',
                                          symbol: 'Rp ',
                                          decimalDigits: 0)
                                      .format(totalHarga),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Teks evaluasi bank sampah
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Detail sampah yang diberikan sudah merupakan hasil evaluasi oleh pihak Bank Sampah Bersinar.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Thank you message
                    const Text(
                      'Terimakasih sudah menyetorkan sampahmu!',
                      style: TextStyle(
                        color: Color(0xFF26A69A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                      // Action buttons
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (phone != '-' && phone.length >= 10)
                              ? shareToWhatsApp
                              : null,
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                          label: const Text(
                            'Bagikan via WhatsApp',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), // hijau WhatsApp
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _downloadNotaAsPdf,
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'Unduh Nota',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
}
