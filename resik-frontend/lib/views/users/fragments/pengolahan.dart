import 'package:flutter/material.dart';

class PengolahanFragment extends StatelessWidget {
  final List<Map<String, dynamic>> items = [
    {
      'title': 'Sampah Organik',
      'icon': Icons.eco,
      'points': [
        'Dijadikan Kompos',
        'Dijadikan Pakan Ternak',
        'Diolah menjadi eco-enzyme untuk keperluan rumah tangga'
      ]
    },
    {
      'title': 'Botol Kaca',
      'icon': Icons.wine_bar,
      'points': ['Dimanfaatkan untuk aneka kerajinan tangan', 'Wadah Serbaguna']
    },
    {
      'title': 'Aluminium',
      'icon': Icons.coffee,
      'points': [
        'Bata Ramah Lingkungan (Ecobrick)',
        'Daur ulang dari kaleng aluminium'
      ]
    },
    {
      'title': 'Botol PET',
      'icon': Icons.local_drink,
      'points': ['Wadah serbaguna', 'Daur ulang botol PET']
    },
    {
      'title': 'Kardus',
      'icon': Icons.all_inbox,
      'points': ['Rak atau Organizer', 'Daur ulang kertas']
    },
    {
      'title': 'Tutup Botol',
      'icon': Icons.radio_button_checked,
      'points': ['Bahan kerajinan tangan seperti gantungan kunci']
    },
    {
      'title': 'Galon',
      'icon': Icons.local_shipping,
      'points': ['Bisa dijual kembali ke distributor resmi', 'Digunakan ulang']
    },
    {
      'title': 'Plastik Kemasan',
      'icon': Icons.shopping_bag,
      'points': [
        'Dipilah dan didaur ulang',
        'Ecobrick atau diproses menjadi biji plastik',
        'Bahan aspal'
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengolahan',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    items[index]['icon'],
                    color: Colors.teal,
                    size: 32,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[index]['title'],
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            items[index]['points'].length,
                            (i) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${i + 1}. ${items[index]['points'][i]}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
