import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/core/qr/qr_join_payload.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Bottom sheet that shows a scannable QR code for joining the host stream.
class HostQrSheet extends StatelessWidget {
  const HostQrSheet({
    super.key,
    required this.websocketUrl,
    this.hostIpAddress,
    this.port,
    this.deviceName = 'Peer View Host',
  });

  final String websocketUrl;
  final String? hostIpAddress;
  final int? port;
  final String deviceName;

  static Future<void> show(
    BuildContext context, {
    required String websocketUrl,
    String? hostIpAddress,
    int? port,
    String deviceName = 'Peer View Host',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => HostQrSheet(
        websocketUrl: websocketUrl,
        hostIpAddress: hostIpAddress,
        port: port,
        deviceName: deviceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = QrJoinPayload(
      websocketUrl: websocketUrl,
      deviceName: deviceName,
      ipAddress: hostIpAddress,
      port: port,
    ).encode();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Join QR Code',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Clients can scan this code to join your stream.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppInfoRow(
              label: 'URL',
              value: websocketUrl,
              selectable: true,
            ),
            const SizedBox(height: 8),
            AppSecondaryButton(
              label: 'Copy URL',
              icon: Icons.copy_rounded,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: websocketUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection URL copied')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
