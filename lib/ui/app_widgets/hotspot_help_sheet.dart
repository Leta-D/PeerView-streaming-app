import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peer_view/constants/app_colors.dart';

class HotspotHelpSheet extends StatelessWidget {
  const HotspotHelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neonColor(0.6),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: AppColors.neonColor(0.6), blurRadius: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.wifi_tethering, color: AppColors.neonColor(1)),
              SizedBox(width: 10),
              Text(
                'Hotspot Setup Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _stepTile('1', Icons.settings, 'Open phone Settings'),
          _stepTile('2', Icons.wifi, 'Go to Hotspot / Tethering'),
          _stepTile('3', Icons.lock, 'Turn ON hotspot and set name & password'),
          _stepTile('4', Icons.qr_code, 'Return to app and generate QR code'),

          const SizedBox(height: 28),

          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonColor(1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                shadowColor: AppColors.neonColor(1),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text(
                'READY',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _stepTile(String step, IconData icon, String text) {
  const Color neon = Color(0xFF00E5FF);

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Neon Step Circle
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: neon, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: neon.withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            step,
            style: const TextStyle(color: neon, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(width: 14),

        Icon(icon, color: neon),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ],
    ),
  );
}
