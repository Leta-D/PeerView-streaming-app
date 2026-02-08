import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text("QR-Scanner")),
      body: BlocBuilder<PermissionHandlerCubit, PermissionHandlerState>(
        builder: (context, state) {
          if (state is PermissionHandlerInitialState) {
            context.read<PermissionHandlerCubit>().requestCammeraPermission();
            return Center(child: CircularProgressIndicator());
          } else if (state is PermissionHandlerLoadingState) {
            return Center(child: CircularProgressIndicator());
          } else if (state is PermissionHandlerGrantedState) {
            return MobileScanner(
              onDetect: (barcode) {
                final value = barcode.raw;

                if (value != null) {
                  AppSettings.openAppSettings(type: AppSettingsType.wifi);
                }
              },
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
    );
  }
}
