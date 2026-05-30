import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/core/di/injection.dart';
import 'package:peer_view_2/features/screen_streaming/cubit/screen_streaming_cubit.dart';
import 'package:peer_view_2/features/screen_viewer/cubit/viewer_cubit.dart';
import 'package:peer_view_2/presentation/main_screens/host_streaming_screen.dart';
import 'package:peer_view_2/presentation/main_screens/stream_settings_screen.dart';
import 'package:peer_view_2/presentation/main_screens/viewer_screen.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderAccent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PulseDot(size: 8),
                          const SizedBox(width: 8),
                          Text(
                            'Peer View',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Stream settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          AppFadeScalePageRoute(
                            page: const StreamSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_rounded),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),

              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.primarySoft,
                      ),
                    ),
                    Text(
                      'Your Role',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        decorationStyle: TextDecorationStyle.solid,
                        decoration: TextDecoration.overline,
                        decorationColor: AppColors.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: Text(
                  'Stream your screen to nearby devices, or join a host on the same Wi‑Fi or hotspot.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: _RoleCard(
                  icon: Icons.cast_rounded,
                  title: 'Host',
                  description:
                      'Capture your screen and broadcast it over a local network  [ LAN ].',
                  accent: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      AppFadeScalePageRoute(
                        page: BlocProvider(
                          create: (_) => sl<ScreenStreamingCubit>(),
                          child: const HostStreamingScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _RoleCard(
                  icon: Icons.tv_rounded,
                  title: 'Viewer',
                  description:
                      'Discover nearby hosts and watch the live stream on this device.',
                  accent: AppColors.primarySoft,
                  onTap: () {
                    Navigator.push(
                      context,
                      AppFadeScalePageRoute(
                        page: BlocProvider(
                          create: (_) => sl<ViewerCubit>(),
                          child: const ViewerScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 2),
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: Text(
                  'Unlimited local streaming',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentBorder: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(icon: icon, color: accent),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: accent),
            ],
          ),
          const SizedBox(height: 14),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
