import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;

class LiveScanPage extends StatefulWidget {
  const LiveScanPage({Key? key}) : super(key: key);

  @override
  State<LiveScanPage> createState() => _LiveScanPageState();
}

class _LiveScanPageState extends State<LiveScanPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  final FlutterVision vision = FlutterVision();
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initCameraAndModel();
  }

  Future<void> _initCameraAndModel() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();

    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/model.tflite',
      modelVersion: 'yolov8',
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });

    _cameraController.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final results = await vision.yoloOnFrame(
          bytesList: image.planes.map((plane) => plane.bytes).toList(),
          imageHeight: image.height,
          imageWidth: image.width,
        );

        setState(() {
          _results = List<Map<String, dynamic>>.from(results);
        });
      } catch (e) {
        print("Error deteksi: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<void> _captureImage() async {
    try {
      setState(() => _isDetecting = true);
      await _cameraController.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile originalImage = await _cameraController.takePicture();
      print("📷 Original image path: ${originalImage.path}");

      // Manual rotate image 90 derajat jika perlu
      final bytes = await File(originalImage.path).readAsBytes();
      final decodedImg = img.decodeImage(bytes);

      if (decodedImg == null) {
        throw Exception("❌ Gagal decode gambar.");
      }

      final rotatedImg = img.copyRotate(decodedImg, angle: 90);

      final rotatedFile = File(originalImage.path)..writeAsBytesSync(img.encodeJpg(rotatedImg));
      print("✅ Manual rotate saved at: ${rotatedFile.path}");

      final result = await vision.yoloOnImage(
        bytesList: rotatedFile.readAsBytesSync(),
        imageHeight: rotatedImg.height,
        imageWidth: rotatedImg.width,
      );

      await vision.closeYoloModel();

      Navigator.pop(context, {
        'file': rotatedFile,
        'result': result,
      });
    } catch (e) {
      print("❌ Gagal capture: $e");
    }
  }

  Future<ui.Image> decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    vision.closeYoloModel();

    // Kembalikan ke portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Live Scan')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text('Live Scan')),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          CustomPaint(
            painter: BoundingBoxPainter(
              results: _results,
              previewSize: _cameraController.value.previewSize!,
              isPortrait: isPortrait,
            ),
            child: Container(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> results;
  final Size previewSize;
  final bool isPortrait;

  BoundingBoxPainter({
    required this.results,
    required this.previewSize,
    required this.isPortrait,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final res in results) {
      final box = res['box'];
      final tag = res['tag'] ?? '';

      if (box == null || box.length < 4) continue;

      final double inputWidth = isPortrait ? previewSize.height : previewSize.width;
      final double inputHeight = isPortrait ? previewSize.width : previewSize.height;

      final double scaleX = size.width / inputWidth;
      final double scaleY = size.height / inputHeight;

      double x1 = box[0] * scaleX;
      double y1 = box[1] * scaleY;
      double x2 = box[2] * scaleX;
      double y2 = box[3] * scaleY;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, boxPaint);

      final textSpan = TextSpan(
        text: '$tag (${(box.length >= 5 ? box[4] * 100 : 0).toStringAsFixed(1)}%)',
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final labelRect = Rect.fromLTWH(
        x1,
        y1 - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(labelRect, bgPaint);
      textPainter.paint(canvas, Offset(x1 + 4, y1 - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}