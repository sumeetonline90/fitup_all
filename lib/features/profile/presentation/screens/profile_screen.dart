import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../activity/domain/entities/activity.dart';
import '../../../activity/domain/entities/activity_stats.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../diet/domain/entities/diet_summary.dart';
import '../../../diet/presentation/providers/diet_providers.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../domain/entities/profile_enums.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';

/// Profile hub — HTML prototype layout; data via providers only.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> profileAsync = ref.watch(userProfileProvider);
    final AsyncValue<FitcoinWallet> walletAsync =
        ref.watch(fitcoinWalletStreamProvider);
    final AsyncValue<ActivityStats> weekly = ref.watch(weeklyStatsProvider);
    final AsyncValue<DietSummary> diet = ref.watch(dailySummaryProvider);
    final AsyncValue<List<WorkoutLog>> recent = ref.watch(recentWorkoutsProvider);

    final UserProfile? p = profileAsync.value;
    final bool loading = profileAsync.isLoading && p == null;

    return Material(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: Text(
              'Profile',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.onSurfaceVariant,
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    )
                  : _ProfileBody(
                      profile: p ??
                          UserProfile(
                            userId: '',
                            email: '',
                            updatedAt: DateTime.now(),
                          ),
                      walletAsync: walletAsync,
                      weekly: weekly,
                      diet: diet,
                      recent: recent,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.profile,
    required this.walletAsync,
    required this.weekly,
    required this.diet,
    required this.recent,
  });

  final UserProfile profile;
  final AsyncValue<FitcoinWallet> walletAsync;
  final AsyncValue<ActivityStats> weekly;
  final AsyncValue<DietSummary> diet;
  final AsyncValue<List<WorkoutLog>> recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NumberFormat fc = NumberFormat('#,###');
    final DateFormat longDateFmt = DateFormat('dd MMM yyyy');
    final String? bmiStr = profile.bmi?.toStringAsFixed(1);
    final int fcBal =
        walletAsync.value?.balance ?? 0;
    final int streak = profile.currentStreakDays;

    int stepsToday = 0;
    weekly.maybeWhen(
      data: (ActivityStats stats) {
        final DateTime d0 = DateTime.now();
        final DateTime day = DateTime(d0.year, d0.month, d0.day);
        for (final Activity a in stats.recentActivities) {
          final DateTime ad = DateTime(
            a.startTime.year,
            a.startTime.month,
            a.startTime.day,
          );
          if (ad == day) {
            stepsToday += a.steps ?? 0;
          }
        }
      },
      orElse: () {},
    );

    String calLine = '—';
    diet.when(
      data: (DietSummary s) {
        calLine = '${s.totalCalories.round()} cal';
      },
      loading: () => calLine = '…',
      error: (_, __) => calLine = '—',
    );

    String workoutLine = '—';
    recent.when(
      data: (List<WorkoutLog> logs) {
        if (logs.isNotEmpty) {
          workoutLine = logs.first.sessionName;
        }
      },
      loading: () => workoutLine = '…',
      error: (_, __) {},
    );

    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            _AvatarRing(
              photoUrl: profile.photoUrl,
              onTap: () => _pickAvatar(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile.displayName ?? 'Your name',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: AppTextStyles.bodyMedium,
        ),
        if (profile.subscriptionTier == SubscriptionTier.pro) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.star, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Pro Member',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/profile/edit'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            'Edit Profile',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Health Snapshot',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniStat(
                label: 'BMI',
                value: bmiStr ?? '—',
                sub: 'Body mass',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Fitcoins',
                value: fc.format(fcBal),
                sub: 'Balance',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Streak',
                value: '$streak',
                sub: 'Days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Quick stats',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniStat(
                label: 'Calories today',
                value: calLine,
                sub: 'Diet',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Steps today',
                value: '$stepsToday',
                sub: 'Activity',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Last workout',
                value: workoutLine,
                sub: 'Workout',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Body metrics',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/edit'),
                    child: Text(
                      'Edit',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _metricRow(
                'Height',
                profile.heightCm != null
                    ? '${profile.heightCm!.toStringAsFixed(0)} cm'
                    : '—',
              ),
              _metricRow(
                'Weight',
                profile.weightKg != null
                    ? '${profile.weightKg!.toStringAsFixed(1)} kg'
                    : '—',
              ),
              _metricRow(
                'Target',
                profile.targetWeightKg != null
                    ? '${profile.targetWeightKg!.toStringAsFixed(1)} kg'
                    : '—',
              ),
              _metricRow(
                'Target date',
                profile.targetWeightDate != null
                    ? longDateFmt.format(profile.targetWeightDate!)
                    : '—',
              ),
              _metricRow(
                'Date of birth',
                profile.dateOfBirth != null
                    ? longDateFmt.format(profile.dateOfBirth!)
                    : '—',
              ),
              _metricRow(
                'Age',
                profile.dateOfBirth != null
                    ? '${DateTime.now().year - profile.dateOfBirth!.year}'
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Goals',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/edit'),
                    child: Text(
                      'Edit',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.goals
                    .map(
                      (HealthGoal g) => Chip(
                        label: Text(
                          g.title,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onBackground,
                          ),
                        ),
                        backgroundColor:
                            AppColors.primaryContainer.withValues(alpha: 0.15),
                        side: BorderSide(color: AppColors.glassBorder),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Daily targets',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              _metricRow(
                'Steps',
                profile.dailyStepGoal != null
                    ? '${profile.dailyStepGoal} steps'
                    : 'Not set',
              ),
              _metricRow(
                'Calorie intake',
                profile.dailyCalorieGoal != null
                    ? '${profile.dailyCalorieGoal} kcal'
                    : 'Not set',
              ),
              _metricRow(
                'Sleep',
                profile.dailySleepGoalMinutes != null
                    ? '${profile.dailySleepGoalMinutes} min'
                    : 'Not set',
              ),
              _metricRow(
                'Water',
                profile.dailyWaterGoalMl != null
                    ? '${profile.dailyWaterGoalMl} ml'
                    : 'Not set',
              ),
              _metricRow(
                'Workout duration',
                profile.dailyWorkoutGoalMinutes != null
                    ? '${profile.dailyWorkoutGoalMinutes} min'
                    : 'Not set',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings, color: AppColors.secondary),
          title: Text('Settings', style: AppTextStyles.bodyLarge),
          trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          onTap: () => context.push('/settings'),
        ),
        const Divider(color: AppColors.outlineVariant),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text(
            'Sign out',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
          ),
          onTap: () async {
            await ref.read(authNotifierProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _metricRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(k, style: AppTextStyles.bodyMedium),
          Text(
            v,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.onBackground),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.headlineLarge.copyWith(
                fontSize: 18,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              sub.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.photoUrl, required this.onTap});

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
              blurRadius: 32,
            ),
            const BoxShadow(
              color: AppColors.primaryContainer,
              blurRadius: 0,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(
                    color: AppColors.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                )
              : const ColoredBox(
                  color: AppColors.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }
}

Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
  final XFile? x = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (x == null) {
    return;
  }
  final bytes = await x.readAsBytes();
  final String uid = ref.read(authStateProvider).value?.id ?? '';
  if (uid.isEmpty) {
    return;
  }
  final String mime = x.mimeType ?? 'image/jpeg';
  await ref.read(profileRepositoryProvider).uploadAvatar(uid, bytes, mime);
}
