import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/meal_type.dart';

/// Bottom sheet: pick breakfast / lunch / dinner / snack, then go to meal log.
Future<void> showMealTypeSelector(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const MealTypeSelector(),
  );
}

class MealTypeSelector extends StatelessWidget {
  const MealTypeSelector({super.key});

  void _pick(BuildContext context, MealType type) {
    Navigator.of(context).pop();
    context.push('/diet/log/${type.name}');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (BuildContext context, ScrollController c) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: c,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
              Text('Log meal', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Choose a meal slot', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 20),
              _MealOption(
                icon: Icons.wb_sunny_outlined,
                title: MealType.breakfast.label,
                subtitle: 'Start the day',
                glow: AppColors.primary,
                onTap: () => _pick(context, MealType.breakfast),
              ),
              const SizedBox(height: 10),
              _MealOption(
                icon: Icons.restaurant_outlined,
                title: MealType.lunch.label,
                subtitle: 'Midday fuel',
                glow: AppColors.secondary,
                onTap: () => _pick(context, MealType.lunch),
              ),
              const SizedBox(height: 10),
              _MealOption(
                icon: Icons.dinner_dining_outlined,
                title: MealType.dinner.label,
                subtitle: 'Evening plate',
                glow: AppColors.tertiary,
                onTap: () => _pick(context, MealType.dinner),
              ),
              const SizedBox(height: 10),
              _MealOption(
                icon: Icons.cookie_outlined,
                title: MealType.snack.label,
                subtitle: 'Quick bite',
                glow: AppColors.secondary,
                onTap: () => _pick(context, MealType.snack),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MealOption extends StatelessWidget {
  const _MealOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.glow,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          glowColor: glow,
          child: Row(
            children: <Widget>[
              Icon(icon, color: glow, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 18,
                        )),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: glow.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
