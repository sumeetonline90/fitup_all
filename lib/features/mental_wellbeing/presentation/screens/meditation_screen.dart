import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/responsive_grid.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/meditation_sound.dart';
import 'meditation_timer_screen.dart' show MeditationTimerRouteExtra;

/// Choose duration and ambient sound.
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  int _minutes = 5;
  MeditationSound _sound = MeditationSound.silent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Meditation', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Duration', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <int>[5, 10, 15, 20].map((int m) {
              return ChoiceChip(
                label: Text('$m min'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Sound', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount:
                responsiveColumns(context, mobile: 2, tablet: 4, desktop: 5, wide: 6),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: MeditationSound.values.map((MeditationSound s) {
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _sound = s),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        switch (s) {
                          MeditationSound.silent => Icons.volume_off_outlined,
                          MeditationSound.rain => Icons.water_drop_outlined,
                          MeditationSound.whiteNoise => Icons.graphic_eq,
                          MeditationSound.forest => Icons.park_outlined,
                        },
                        color: _sound == s
                            ? AppColors.secondary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.label,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Center(
            child: NeonButton(
              label: 'Begin',
              onPressed: () => context.push(
                '/mental/meditation/timer',
                extra: MeditationTimerRouteExtra(
                  totalSeconds: _minutes * 60,
                  sound: _sound,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
