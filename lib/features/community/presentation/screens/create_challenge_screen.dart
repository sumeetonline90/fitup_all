import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/challenge.dart';
import '../providers/community_providers.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final TextEditingController _opponent = TextEditingController();
  final TextEditingController _target = TextEditingController(text: '10000');
  ChallengeMetric _metric = ChallengeMetric.steps;

  @override
  void dispose() {
    _opponent.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Challenge?> state = ref.watch(createChallengeProvider);
    ref.listen<AsyncValue<Challenge?>>(createChallengeProvider, (_, AsyncValue<Challenge?> next) {
      next.whenOrNull(
        data: (Challenge? c) {
          if (c == null || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duel created: ${c.challengeCode}')),
          );
          context.pop();
        },
      );
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Duel Challenge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: <Widget>[
          Text(
            'One-on-one private challenge. Share and settle it on the leaderboard.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            glowColor: AppColors.tertiary,
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _opponent,
                  decoration: const InputDecoration(labelText: 'Opponent user id'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ChallengeMetric>(
                  initialValue: _metric,
                  items: ChallengeMetric.values
                      .map(
                        (ChallengeMetric e) => DropdownMenuItem<ChallengeMetric>(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: (ChallengeMetric? v) =>
                      setState(() => _metric = v ?? _metric),
                  decoration: const InputDecoration(labelText: 'Metric'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _target,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NeonButton(
            label: state.isLoading ? 'Creating...' : 'Create Duel',
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref.read(createChallengeProvider.notifier).create(
                          CreateChallengeInput(
                            opponentId: _opponent.text.trim(),
                            metric: _metric,
                            startsAt: DateTime.now(),
                            endsAt: DateTime.now().add(const Duration(days: 7)),
                            targetValue: int.tryParse(_target.text) ?? 10000,
                          ),
                        );
                  },
          ),
        ],
      ),
    );
  }
}
