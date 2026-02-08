import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:peer_view/constants/app_colors.dart';
import 'package:peer_view/logic/permission_handler/permission_handler_cubit.dart';
import 'package:peer_view/logic/permission_handler/permission_handler_state.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.bgDark(1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark(1),
            foregroundColor: AppColors.red(0.6),
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'QR Scanner',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(
            child: BlocBuilder<PermissionHandlerCubit, PermissionHandlerState>(
              builder: (context, state) {
                if (state is PermissionHandlerInitialState) {
                  context
                      .read<PermissionHandlerCubit>()
                      .requestCammeraPermission();
                  return Center(child: CircularProgressIndicator());
                } else if (state is PermissionHandlerLoadingState) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is PermissionHandlerGrantedState) {
                  return Column(
                    children: [
                      Text(
                        'Scan Host QR to Join',
                        style: TextStyle(
                          color: AppColors.red(1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SizedBox(
                          height: screenSize.height / 2,
                          child: MobileScanner(
                            onDetect: (barcode) {
                              final value = barcode.raw;

                              if (value != null) {
                                AppSettings.openAppSettings(
                                  type: AppSettingsType.wifi,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (state is PermissionHandlerDeniedState ||
                    state is PermissionHandlerPermanentlyDeniedState) {
                  return Center(
                    child: Column(
                      children: [
                        Text(
                          state is PermissionHandlerDeniedState
                              ? "camera permmision is required to scan"
                              : "camera permmision is Permanently denied",
                        ),
                        ElevatedButton(
                          onPressed: () {
                            state is PermissionHandlerDeniedState
                                ? context
                                      .read<PermissionHandlerCubit>()
                                      .requestCammeraPermission()
                                : AppSettings.openAppSettings().then((value) {
                                    context
                                        .read<PermissionHandlerCubit>()
                                        .requestCammeraPermission();
                                  });
                          },
                          child: Text(
                            state is PermissionHandlerDeniedState
                                ? "Ask again"
                                : "Open setting",
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Text("Some error");
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
