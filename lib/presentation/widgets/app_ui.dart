import 'package:flutter/material.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

/// Rounded dark surface card used across Peer View screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.accentBorder = false,
    this.breathe = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool accentBorder;
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentBorder ? AppColors.borderAccent : AppColors.border,
        ),
        boxShadow: accentBorder && !breathe
            ? const [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );

    Widget result = content;
    if (breathe) {
      result = BreathingGlow(
        enabled: true,
        color: AppColors.primary,
        child: content,
      );
    }

    if (onTap == null) {
      return result;
    }

    return ScaleOnTap(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: result,
      ),
    );
  }
}

/// Section label with optional trailing action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Soft pill status chip with optional live pulse.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.filled = true,
    this.pulse = false,
  });

  final String label;
  final Color color;
  final bool filled;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            PulseDot(color: color, size: 6, enabled: true),
            const SizedBox(width: 6),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              label,
              key: ValueKey(label),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label / value row for network and status details.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: valueStyle)
                : Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

/// Circular icon badge used in role cards and list tiles.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.size = 56,
    this.iconSize = 26,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.iconCircle,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 16,
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// Empty / loading placeholder block.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.searching = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: AppCard(
        child: Column(
          children: [
            if (searching)
              const SearchingRadar(size: 84)
            else
              AppIconBadge(icon: icon, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width primary pill button.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label),
    );
  }
}

/// Full-width secondary outline pill button.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.close_rounded),
      label: Text(label),
    );
  }
}
