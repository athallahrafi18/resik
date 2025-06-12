import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  bool _hasScanned = false;
  bool _isLoading = false;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();

    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final scanBoxWidth = size.width * 0.8;
    final scanBoxHeight = size.height * 0.18;
    final left = (size.width - scanBoxWidth) / 2;
    final top = (size.height - scanBoxHeight) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // Kamera
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture capture) async {
              final List<Barcode> barcodes = capture.barcodes;

              if (!_hasScanned && !_isLoading && barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;

                if (code != null && code.isNotEmpty) {
                  setState(() {
                    _hasScanned = true;
                    _isLoading = true;
                  });

                  _laserController.stop(); // stop laser animasi

                  await Future.delayed(Duration(seconds: 1)); // simulasi loading

                  if (mounted) {
                    Navigator.pop(context, code);
                  }
                }
              }
            },
          ),

          // Overlay transparan dan kotak
          Positioned.fill(
            child: Stack(
              children: [
                // Area gelap di luar kotak
                _buildOverlayMask(size, top, left, scanBoxWidth, scanBoxHeight),

                // Kotak scan
                Positioned(
                  top: top,
                  left: left,
                  child: Container(
                    width: scanBoxWidth,
                    height: scanBoxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.tealAccent, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Laser animasi
                if (!_isLoading)
                  Positioned(
                    top: top,
                    left: left,
                    child: SizedBox(
                      width: scanBoxWidth,
                      height: scanBoxHeight,
                      child: AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: LaserPainter(
                              progress: _laserAnimation.value,
                              color: Colors.redAccent,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Teks panduan
                Positioned(
                  top: top + scanBoxHeight + 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Arahkan barcode ke dalam kotak",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tombol back
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),

          // Spinner loading
          if (_isLoading)
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CircularProgressIndicator(
                  color: Colors.tealAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayMask(Size size, double top, double left, double boxWidth, double boxHeight) {
    return Stack(
      children: [
        // Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // Bottom
        Positioned(
          top: top + boxHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // Left
        Positioned(
          top: top,
          left: 0,
          width: left,
          height: boxHeight,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // Right
        Positioned(
          top: top,
          right: 0,
          width: left,
          height: boxHeight,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
      ],
    );
  }
}

//  Custom painter untuk laser merah
class LaserPainter extends CustomPainter {
  final double progress;
  final Color color;

  LaserPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final laserY = size.height * progress;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, laserY),
      Offset(size.width, laserY),
      paint,
    );
  }

  @override
  bool shouldRepaint(LaserPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
