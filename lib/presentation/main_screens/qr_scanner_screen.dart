import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/core/qr/qr_join_payload.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen that scans a host join QR and returns a [QrJoinPayload].
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  static Future<QrJoinPayload?> open(BuildContext context) {
    return Navigator.of(context).push<QrJoinPayload>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  bool _permissionDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ensureCameraPermission();
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) {
      return;
    }

    if (status.isGranted || status.isLimited) {
      setState(() => _permissionDenied = false);
      return;
    }

    setState(() {
      _permissionDenied = true;
      _errorMessage = status.isPermanentlyDenied
          ? 'Camera permission is permanently denied. Enable it in settings.'
          : 'Camera permission is required to scan QR codes.';
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) {
        continue;
      }

      final payload = QrJoinPayload.tryParse(raw);
      if (payload == null) {
        setState(() {
          _errorMessage = 'Unrecognized QR code. Scan a Peer View host code.';
        });
        continue;
      }

      _handled = true;
      Navigator.of(context).pop(payload);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Host QR')),
      body: _permissionDenied
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppEmptyState(
                    icon: Icons.camera_alt_outlined,
                    title: 'Camera access needed!',
                    message: _errorMessage,
                  ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    label: 'Open Settings',
                    icon: Icons.settings_rounded,
                    onPressed: openAppSettings,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    onPressed: _ensureCameraPermission,
                  ),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                IgnorePointer(
                  child: CustomPaint(painter: _ScannerOverlayPainter()),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AppCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Point the camera at the host QR code',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cutout = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout, const Radius.circular(24)),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
