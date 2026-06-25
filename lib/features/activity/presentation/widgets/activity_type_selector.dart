import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/activity.dart';

/// Bottom sheet: pick Run / Walk / Cycle / Swim.
Future<void> showActivityTypeSelector(
  BuildContext context, {
  required void Function(ActivityType type) onActivitySelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => ActivityTypeSelector(
      onActivitySelected: onActivitySelected,
    ),
  );
}

class ActivityTypeSelector extends StatelessWidget {
  const ActivityTypeSelector({
    super.key,
    required this.onActivitySelected,
  });

  final void Function(ActivityType type) onActivitySelected;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (BuildContext context, ScrollController scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose activity',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Track pace & steps',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _TypeCard(
                emoji: '🏃',
                title: 'Run',
                description: 'Track pace & steps',
                glowColor: AppColors.secondary,
                onTap: () {
                  Navigator.of(context).pop();
                  onActivitySelected(ActivityType.run);
                },
              ),
              const SizedBox(height: 12),
              _TypeCard(
                emoji: '🚶',
                title: 'Walk',
                description: 'Track pace & steps',
                glowColor: AppColors.primaryContainer,
                onTap: () {
                  Navigator.of(context).pop();
                  onActivitySelected(ActivityType.walk);
                },
              ),
              const SizedBox(height: 12),
              _TypeCard(
                emoji: '🚴',
                title: 'Cycle',
                description: 'Track speed & distance',
                glowColor: AppColors.secondary,
                onTap: () {
                  Navigator.of(context).pop();
                  onActivitySelected(ActivityType.cycle);
                },
              ),
              const SizedBox(height: 12),
              _TypeCard(
                emoji: '🏊',
                title: 'Swim',
                description: 'Track duration & calories',
                glowColor: AppColors.tertiary,
                onTap: () {
                  Navigator.of(context).pop();
                  onActivitySelected(ActivityType.swim);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.glowColor,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: GlassCard(
          glowColor: glowColor,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 20,
                        )),
                    const SizedBox(height: 4),
                    Text(description, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: glowColor.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
