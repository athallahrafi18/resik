import 'package:flutter/material.dart';
import 'pengaturan_chat.dart';

class PengaturanFragment extends StatelessWidget {
  const PengaturanFragment({Key? key}) : super(key: key);

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
          'Pengaturan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE0F7FA),
          ),
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 300),
            painter: WavePainter(),
          ),
          Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF26A69A),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Bank Sampah Bersinar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF26A69A),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFF26A69A),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Baleendah, Kabupaten Bandung',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF26A69A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Administrator',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF26A69A),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // --- Tombol Add Account di-comment ---
                    /*
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF26A69A)),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF26A69A),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Add Account',
                        style: TextStyle(
                          color: Color(0xFF26A69A),
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        // Logika untuk Add Account
                      },
                    ),
                    SizedBox(height: 10),
                    */
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF26A69A)),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF26A69A),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Chats',
                        style: TextStyle(
                          color: Color(0xFF26A69A),
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF26A69A),
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PengaturanChatView(
                              userName: 'khoerunisa alfin',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 20),
                  child: TextButton.icon(
                    onPressed: () {
                      // Arahkan ke halaman login dan hapus semua history stack sebelumnya
                      Navigator.of(context).pushNamedAndRemoveUntil('/login_view', (route) => false);
                    },
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0F7FA)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
