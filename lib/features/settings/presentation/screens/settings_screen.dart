import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/failures.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/url_launcher_util.dart';
import '../../../../services/data_export_service.dart';
import '../../../../services/health_connect_service.dart';
import '../../../../services/trace_log_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/app_settings.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/fitup_toggle.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/settings_providers.dart';
import '../providers/ai_usage_provider.dart';

/// Settings hub — grouped GlassCards; optimistic toggles via [AppSettingsNotifier].
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _traceBusy = false;

  Future<void> _setTraceEnabled(bool enabled) async {
    setState(() => _traceBusy = true);
    await TraceLogService.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _traceBusy = false);
  }

  Future<void> _setIncludeGps(bool enabled) async {
    setState(() => _traceBusy = true);
    await TraceLogService.setIncludeGps(enabled);
    if (!mounted) return;
    setState(() => _traceBusy = false);
  }

  Future<void> _shareTraceLogs() async {
    try {
      await TraceLogService.shareLogs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trace logs shared')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share logs: $e')),
      );
    }
  }

  Future<void> _clearTraceLogs() async {
    setState(() => _traceBusy = true);
    await TraceLogService.clearAll();
    if (!mounted) return;
    setState(() => _traceBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trace logs cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSettings> settingsAsync =
        ref.watch(settingsNotifierProvider);
    final AsyncValue<UserProfile> profileAsync =
        ref.watch(userProfileProvider);
    final AsyncValue aiUsageAsync = ref.watch(aiUsageSnapshotProvider);
    final bool traceEnabled = TraceLogService.isEnabled;
    final bool includeGps = TraceLogService.includeGpsInLog;

    // Scaffold is required so Material-dependent widgets (ListTile, CircleAvatar,
    // Divider, SliverAppBar, Chip, etc.) have a Material ancestor in the tree.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: settingsAsync.when(
        data: (AppSettings s) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  AppLocalizations.of(context).settingsTitle,
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    const SectionHeader(label: 'Account'),
                    GlassCard(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: <Widget>[
                          profileAsync.maybeWhen(
                            data: (UserProfile p) => ListTile(
                              leading: CircleAvatar(
                                backgroundImage: p.photoUrl != null
                                    ? NetworkImage(p.photoUrl!)
                                    : null,
                                child: p.photoUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                p.displayName ?? 'User',
                                style: AppTextStyles.bodyLarge,
                              ),
                              subtitle: Text(
                                p.email,
                                style: AppTextStyles.bodyMedium,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/profile/edit'),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                          const Divider(height: 1, color: AppColors.outlineVariant),
                          ListTile(
                            title: Text('Subscription', style: AppTextStyles.bodyLarge),
                            subtitle: Text(
                              profileAsync.maybeWhen(
                                data: (UserProfile p) =>
                                    p.subscriptionTier == SubscriptionTier.pro
                                        ? 'Pro · renews ${_fmt(p.subscriptionRenewal)}'
                                        : 'Free',
                                orElse: () => '—',
                              ),
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: profileAsync.maybeWhen(
                              data: (UserProfile p) =>
                                  p.subscriptionTier == SubscriptionTier.pro
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            gradient: AppColors
                                                .secondaryToPrimaryGradient,
                                          ),
                                          child: Text(
                                            'PRO',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: AppColors.background,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.chevron_right),
                              orElse: () => const SizedBox.shrink(),
                            ),
                            onTap: () => launchSubscriptionFlow(context),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(label: 'Notifications'),
                    _NotificationsBlock(
                      settings: s,
                      onChanged: (AppSettings next) {
                        ref.read(settingsNotifierProvider.notifier).saveSettings(next);
                      },
                    ),
                    const SectionHeader(label: 'Preferences'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Theme', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: FitupThemePreference.values.map((FitupThemePreference t) {
                              final bool sel = s.themePreference == t;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Material(
                                    color: sel
                                        ? AppColors.primaryContainer.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    child: InkWell(
                                      onTap: () {
                                        ref
                                            .read(settingsNotifierProvider.notifier)
                                            .saveSettings(
                                              s.copyWith(themePreference: t),
                                            );
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Center(
                                          child: Text(
                                            _themeLabel(t),
                                            style: AppTextStyles.labelLarge.copyWith(
                                              fontSize: 12,
                                              color: sel
                                                  ? AppColors.primaryContainer
                                                  : AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('Units', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _UnitChip(
                                  label: 'Metric',
                                  selected: s.useMetricUnits,
                                  onTap: () => ref
                                      .read(settingsNotifierProvider.notifier)
                                      .saveSettings(
                                        s.copyWith(useMetricUnits: true),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _UnitChip(
                                  label: 'Imperial',
                                  selected: !s.useMetricUnits,
                                  onTap: () => ref
                                      .read(settingsNotifierProvider.notifier)
                                      .saveSettings(
                                        s.copyWith(useMetricUnits: false),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              AppLocalizations.of(context).languageTitle,
                              style: AppTextStyles.bodyLarge,
                            ),
                            subtitle: Text(
                              _languageDisplayName(
                                context,
                                s.languageCode ?? 'en',
                              ),
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _pickLanguage(context, ref, s),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(label: 'AI usage'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Gemini API calls (local counter)',
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          aiUsageAsync.when(
                            loading: () => const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (Object _, StackTrace __) =>
                                Text(
                              'Usage unavailable',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            data: (dynamic snapshot) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Total calls: ${snapshot.totalCalls}',
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Last hour: ${snapshot.callsLastHour} '
                                    '(Flash: ${snapshot.flashCalls}, '
                                    'Flash-Lite: ${snapshot.flashLiteCalls}, '
                                    'Pro: ${snapshot.proCalls})',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Estimated tokens (prompt/response): '
                                    '${snapshot.totalEstimatedPromptTokens} / '
                                    '${snapshot.totalEstimatedResponseTokens}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By model tokens — Flash: ${snapshot.flashEstimatedTokens}, '
                                    'Flash-Lite: ${snapshot.flashLiteEstimatedTokens}, '
                                    'Pro: ${snapshot.proEstimatedTokens}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(label: 'Field diagnostics (no USB)'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _RowToggle(
                            label: 'Enable field diagnostics logs',
                            value: traceEnabled,
                            onChanged: _traceBusy
                                ? null
                                : (bool v) => _setTraceEnabled(v),
                          ),
                          _RowToggle(
                            label: 'Include GPS lines',
                            value: includeGps,
                            onChanged: traceEnabled && !_traceBusy
                                ? (bool v) => _setIncludeGps(v)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            traceEnabled
                                ? 'Log file: ${TraceLogService.primaryLogPath ?? "—"}'
                                : 'Turn this on to generate logs for field testing.',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton(
                                  onPressed: traceEnabled && !_traceBusy
                                      ? _shareTraceLogs
                                      : null,
                                  child: const Text('Share logs'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: traceEnabled && !_traceBusy
                                      ? _clearTraceLogs
                                      : null,
                                  child: const Text('Clear'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(label: 'Privacy & data'),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              'Export my data',
                              style: AppTextStyles.bodyLarge,
                            ),
                            trailing: _exporting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.share_outlined),
                            onTap: _exporting
                                ? null
                                : () async {
                                    final UserProfile? p =
                                        profileAsync.value;
                                    if (p == null || p.userId.isEmpty) {
                                      return;
                                    }
                                    setState(() => _exporting = true);
                                    final result = await getIt<DataExportService>()
                                        .exportUserData(p.userId);
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() => _exporting = false);
                                    result.fold(
                                      (f) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$f')),
                                        );
                                      },
                                      (String path) async {
                                        await Share.shareXFiles(
                                          <XFile>[XFile(path)],
                                        );
                                      },
                                    );
                                  },
                          ),
                          ListTile(
                            title: Text(
                              'Privacy policy',
                              style: AppTextStyles.bodyLarge,
                            ),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => _openUrl(
                              'https://fitup.app/privacy',
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Terms of service',
                              style: AppTextStyles.bodyLarge,
                            ),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => _openUrl(
                              'https://fitup.app/terms',
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Health data permissions',
                              style: AppTextStyles.bodyLarge,
                            ),
                            trailing: const Icon(Icons.favorite_outline),
                            onTap: () async {
                              final bool granted =
                                  await getIt<HealthConnectService>()
                                      .requestPermissions();
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    granted
                                        ? 'Health permissions granted.'
                                        : 'Could not grant health permissions. Please try again.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(label: 'About'),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: <Widget>[
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (BuildContext context, AsyncSnapshot<PackageInfo> snap) {
                              return ListTile(
                                title: Text(
                                  'Version',
                                  style: AppTextStyles.bodyLarge,
                                ),
                                trailing: Text(
                                  snap.data?.version ?? '—',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              );
                            },
                          ),
                          ListTile(
                            title: Text(
                              'Rate Fitup',
                              style: AppTextStyles.bodyLarge,
                            ),
                            onTap: () => _openUrl(
                              'https://play.google.com/store/apps/details?id=com.fitup.app',
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Help & support',
                              style: AppTextStyles.bodyLarge,
                            ),
                            onTap: () => _openUrl('https://fitup.app/support'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        'Sign out',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
                      ),
                      onTap: () async {
                        final bool? ok = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            title: const Text('Sign out?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await ref.read(authNotifierProvider.notifier).signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Delete account',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
                      ),
                      onTap: () => _confirmDelete(context),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
        error: (Object e, _) => Center(
          child: Text(
            e is Failure
                ? (e.message ?? 'Could not load settings.')
                : 'Could not load settings.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ),
    );
  }

  String _languageDisplayName(BuildContext context, String code) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return switch (code) {
      'hi' => l10n.languageHindi,
      _ => l10n.languageEnglish,
    };
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppSettings s,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String current = s.languageCode ?? 'en';
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      showDragHandle: true,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                l10n.languagePickerHint,
                style: AppTextStyles.labelLarge,
              ),
            ),
            ListTile(
              title: Text(l10n.languageEnglish),
              trailing: current == 'en'
                  ? const Icon(Icons.check, color: AppColors.primaryContainer)
                  : null,
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
            ListTile(
              title: Text(l10n.languageHindi),
              trailing: current == 'hi'
                  ? const Icon(Icons.check, color: AppColors.primaryContainer)
                  : null,
              onTap: () => Navigator.pop(ctx, 'hi'),
            ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await ref.read(settingsNotifierProvider.notifier).saveSettings(
            s.copyWith(languageCode: picked),
          );
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) {
      return '—';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _themeLabel(FitupThemePreference t) => switch (t) {
        FitupThemePreference.light => 'Light',
        FitupThemePreference.dark => 'Dark',
        FitupThemePreference.system => 'System',
      };

  Future<void> _openUrl(String url) async {
    final result = await UrlLauncherUtil.launch(url);
    if (!mounted) return;
    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? '$f')),
        );
      },
      (_) {},
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final TextEditingController c = TextEditingController();
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Type DELETE to confirm.'),
            TextField(
              controller: c,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(labelText: 'DELETE'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (c.text.trim() == 'DELETE') {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    c.dispose();
    if (go == true && context.mounted) {
      final result = await ref.read(authRepositoryProvider).deleteAccount();
      result.fold(
        (f) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message ?? 'Failed')),
          );
        },
        (_) {
          if (context.mounted) {
            context.go('/login');
          }
        },
      );
    }
  }
}

class _NotificationsBlock extends StatelessWidget {
  const _NotificationsBlock({
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool master = settings.masterPushEnabled;
    final double opacity = master ? 1 : 0.4;
    return Opacity(
      opacity: opacity,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _RowToggle(
              label: 'Push notifications',
              value: master,
              onChanged: (bool v) => onChanged(settings.copyWith(masterPushEnabled: v)),
            ),
            _RowToggle(
              label: 'Meal reminders',
              value: settings.mealReminders && master,
              onChanged: master
                  ? (bool v) => onChanged(settings.copyWith(mealReminders: v))
                  : null,
            ),
            _RowToggle(
              label: 'Hydration',
              value: settings.hydrationReminders && master,
              onChanged: master
                  ? (bool v) => onChanged(settings.copyWith(hydrationReminders: v))
                  : null,
            ),
            _RowToggle(
              label: 'Workout',
              value: settings.workoutReminders && master,
              onChanged: master
                  ? (bool v) => onChanged(settings.copyWith(workoutReminders: v))
                  : null,
            ),
            _RowToggle(
              label: 'Sleep',
              value: settings.sleepReminders && master,
              onChanged: master
                  ? (bool v) => onChanged(settings.copyWith(sleepReminders: v))
                  : null,
            ),
            _RowToggle(
              label: 'Medication',
              value: settings.medicationReminders && master,
              onChanged: master
                  ? (bool v) => onChanged(settings.copyWith(medicationReminders: v))
                  : null,
            ),
            _RowToggle(
              label: 'AI nudges',
              value: settings.aiNudges && master,
              onChanged: master
                  ? (bool v) => onChanged(settings.copyWith(aiNudges: v))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowToggle extends StatelessWidget {
  const _RowToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: AppTextStyles.bodyLarge),
          ),
          FitupToggle(
            value: value,
            onChanged: onChanged ?? (_) {},
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
