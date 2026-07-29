import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tunefy/theme/tunefy_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TunefyColors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: (capture) {
              if (_found) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _found = true;
              Navigator.pop(context, raw);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: TunefyColors.white, size: 20),
                  ),
                ),
                Row(
                  children: [
                    Image.asset('images/hivefy_logo.png', width: 28, height: 28),
                    const SizedBox(width: 8),
                    const Text('Tunefy', style: TextStyle(
                      fontFamily: 'AB', fontSize: 18, color: TunefyColors.white, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: TunefyColors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0, right: 0,
            child: const Center(
              child: Text('Placez le QR Code dans le cadre', style: TextStyle(
                fontFamily: 'AM', fontSize: 14, color: TunefyColors.white,
              )),
            ),
          ),
        ],
      ),
    );
  }
}
