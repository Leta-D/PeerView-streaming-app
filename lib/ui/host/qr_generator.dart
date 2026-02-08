import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peer_view/constants/app_colors.dart';
import 'package:peer_view/ui/app_widgets/hotspot_help_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({super.key});

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator>
    with SingleTickerProviderStateMixin {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  String? qrData;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String _generateWifiQr(String ssid, String password) {
    return 'WIFI:T:WPA;S:$ssid;P:$password;;';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark(1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark(1),
            foregroundColor: AppColors.neonColor(0.6),
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'HOST QR',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();

                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF0B0F1A),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => const HotspotHelpSheet(),
                  );
                },
                icon: Icon(Icons.question_mark_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark(1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neonColor(0.4)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOTSPOT CONFIGURATION',
                      style: TextStyle(
                        color: AppColors.neonColor(1),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _GamingTextField(
                      controller: _ssidController,
                      label: 'HOTSPOT NAME',
                      icon: Icons.wifi,
                    ),

                    const SizedBox(height: 12),

                    _GamingTextField(
                      controller: _passwordController,
                      label: 'PASSWORD',
                      icon: Icons.lock,
                      obscure: true,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonColor(1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (_ssidController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty) {
                            setState(() {
                              qrData = _generateWifiQr(
                                _ssidController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Please Fill Both Hotspot Name and Password",
                                  style: TextStyle(
                                    color: AppColors.neonColor(1),
                                  ),
                                ),
                                backgroundColor: AppColors.cardDark(1),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'GENERATE QR',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (qrData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'SCAN TO JOIN',
                      style: TextStyle(
                        color: AppColors.neonColor(1),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, __) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonColor(
                                  0.3 + (_glowController.value * 0.3),
                                ),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: QrImageView(data: qrData!, size: 220),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'SSID: ${_ssidController.text}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'PASSWORD: ${_passwordController.text}',
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Client scans QR → Wi-Fi settings open → connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GamingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  const _GamingTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.neonColor(1)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.neonColor(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.neonColor(1), width: 2),
        ),
      ),
      onTapOutside: (event) => FocusManager().primaryFocus!.hasPrimaryFocus
          ? FocusManager().primaryFocus!.unfocus()
          : null,
    );
  }
}
