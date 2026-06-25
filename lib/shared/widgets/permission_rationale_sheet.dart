import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/permission_providers.dart';
import '../../services/logger_service.dart';
import '../../services/permission_service.dart';
import 'glass_card.dart';
import 'neon_button.dart';

/// Glass-card bottom sheet explaining required permissions on first launch.
class PermissionRationaleSheet extends ConsumerWidget {
  const PermissionRationaleSheet({super.key, required this.permissionState});

  final AppPermissionState permissionState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPermissionState s = ref.watch(permissionStateProvider).maybeWhen(
          data: (AppPermissionState v) => v,
          orElse: () => permissionState,
        );
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fitup works best with…',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!s.locationGranted)
                const _PermissionRow(
                  icon: Icons.location_on_rounded,
                  title: 'Location',
                  purpose: 'Track outdoor workouts and routes.',
                ),
              if (!s.healthGranted)
                const _PermissionRow(
                  icon: Icons.favorite_rounded,
                  title: 'Health data',
                  purpose: 'Sync steps, sleep, and heart rate from your device.',
                ),
              if (!s.notificationGranted)
                const _PermissionRow(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  purpose: 'Get meal reminders and AI nudges.',
                ),
              const SizedBox(height: 16),
              if (!s.locationGranted)
                NeonButton(
                  label: 'Grant Location',
                  icon: Icons.location_on_rounded,
                  onPressed: () async {
                    LoggerService.i(
                      'PermissionRationaleSheet.onPressed Grant Location',
                    );
                    await ref.read(permissionServiceProvider).requestLocation();
                    ref.invalidate(permissionStateProvider);
                    final AppPermissionState latest =
                        await ref.read(permissionServiceProvider).getPermissionState();
                    if (!context.mounted) return;
                    if (latest.locationGranted && latest.healthGranted && latest.notificationGranted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              if (!s.healthGranted) ...<Widget>[
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Grant Health Connect',
                  icon: Icons.favorite_rounded,
                  onPressed: () async {
                    LoggerService.i(
                      'PermissionRationaleSheet.onPressed Grant Health Connect',
                    );
                    await ref
                        .read(permissionServiceProvider)
                        .requestHealthPermissions();
                    ref.invalidate(permissionStateProvider);
                    final AppPermissionState latest =
                        await ref.read(permissionServiceProvider).getPermissionState();
                    if (!context.mounted) return;
                    if (latest.locationGranted && latest.healthGranted && latest.notificationGranted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
              if (!s.notificationGranted) ...<Widget>[
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Enable Notifications',
                  icon: Icons.notifications_rounded,
                  onPressed: () async {
                    await ref
                        .read(permissionServiceProvider)
                        .requestNotifications();
                    ref.invalidate(permissionStateProvider);
                    final AppPermissionState latest =
                        await ref.read(permissionServiceProvider).getPermissionState();
                    if (!context.mounted) return;
                    if (latest.locationGranted && latest.healthGranted && latest.notificationGranted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
              if (s.locationGranted && s.healthGranted && s.notificationGranted) ...<Widget>[
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Done',
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.purpose,
  });

  final IconData icon;
  final String title;
  final String purpose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 3),
                Text(
                  purpose,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

