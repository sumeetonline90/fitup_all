import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/community_event.dart';
import '../providers/community_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CommunityEvent> asyncEvent =
        ref.watch(eventByIdProvider(eventId));
    final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
    final FitupUser? me = switch (auth) {
      AsyncData<FitupUser?>(:final value) => value,
      _ => null,
    };

    return asyncEvent.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  e is Failure ? (e.message ?? 'Error') : 'Event not found',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(eventByIdProvider(eventId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (CommunityEvent event) => _EventDetailBody(
        event: event,
        me: me,
        eventId: eventId,
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  const _EventDetailBody({
    required this.event,
    required this.me,
    required this.eventId,
  });

  final CommunityEvent event;
  final FitupUser? me;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? myId = me?.id;
    final String organizerActionUserId = myId ?? '';
    final bool joined = event.isJoinedBy(myId);
    final bool done = event.isCompleted;
    final bool cancelled = event.status == EventStatus.cancelled;
    final bool canDelete =
        myId != null && myId == event.organizerId && !cancelled;
    final bool canExtend =
        myId != null && myId == event.organizerId && !done && !cancelled;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: _RouteHeroPainter(),
                      child: const SizedBox.expand(),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 8,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer.withValues(
                            alpha: 0.85,
                          ),
                        ),
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 8,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer.withValues(
                            alpha: 0.85,
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ),
                    const Positioned(
                      left: 48,
                      bottom: 40,
                      child: Icon(Icons.place, color: AppColors.secondary, size: 32),
                    ),
                    const Positioned(
                      right: 48,
                      bottom: 64,
                      child: Icon(Icons.flag, color: AppColors.primary, size: 28),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Chip(
                          label: Text(event.type.name, style: AppTextStyles.labelSmall),
                          backgroundColor:
                              AppColors.secondary.withValues(alpha: 0.2),
                        ),
                        Chip(
                          label: Text(
                            event.isPublic ? 'Public' : 'Private',
                            style: AppTextStyles.labelSmall,
                          ),
                          backgroundColor:
                              AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title,
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.event, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat.yMMMEd().add_jm().format(event.startsAt),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.place_outlined,
                            size: 18, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.locationLabel,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: AppColors.surfaceContainerHighest,
                            child: Text(
                              event.organizerName.isNotEmpty
                                  ? event.organizerName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Organiser', style: AppTextStyles.bodySmall),
                                Text(
                                  event.organizerName,
                                  style: AppTextStyles.labelLarge,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: myId == null || event.organizerId == myId
                                ? null
                                : () async {
                                    final r = await ref
                                        .read(communityRepositoryProvider)
                                        .followUser(myId, event.organizerId);
                                    r.fold(
                                      (Failure f) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(f.message ?? 'Follow failed'),
                                          ),
                                        );
                                      },
                                      (_) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Following')),
                                        );
                                      },
                                    );
                                  },
                            child: const Text('Follow'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Row(
                        children: <Widget>[
                          _miniStat('Participants', '${event.participantCount}'),
                          _miniStat(
                            'Distance',
                            event.distanceKm != null
                                ? '${event.distanceKm} km'
                                : '—',
                          ),
                          _miniStat('Reward', '+${event.rewardFc} FC'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Joining',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: List<Widget>.generate(
                          6,
                          (int i) => Align(
                            widthFactor: 0.82,
                            child: CircleAvatar(
                              backgroundColor:
                                  AppColors.surfaceContainerHighest,
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: AppTextStyles.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '+${(event.participantCount - 6).clamp(0, 999)} others',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Text('About', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Text(event.about, style: AppTextStyles.bodyLarge),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.background.withValues(alpha: 0.95),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: done
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: null,
                            child: Text(
                              'View Results',
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                          if (canDelete) ...<Widget>[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () async {
                                final bool? ok = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Delete event?'),
                                      content: const Text(
                                        'This removes the event from listings and the event leaderboard.',
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (ok != true) return;
                                final r = await ref
                                    .read(communityRepositoryProvider)
                                    .deleteEvent(organizerActionUserId, event.id);
                                if (!context.mounted) return;
                                r.fold(
                                  (Failure f) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          f.message ?? 'Delete failed',
                                        ),
                                      ),
                                    );
                                  },
                                  (_) {
                                    ref.invalidate(upcomingEventsProvider);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('Event deleted'),
                                      ),
                                    );
                                    context.go('/community/events');
                                  },
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              child: const Text('Delete Event'),
                            ),
                          ],
                        ],
                      )
                    : canDelete || canExtend
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (canExtend) ...<Widget>[
                                OutlinedButton(
                                  onPressed: () async {
                                    final int? days = await showDialog<int>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        final TextEditingController c =
                                            TextEditingController(text: '7');
                                        return AlertDialog(
                                          title: const Text('Extend event'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              const Text(
                                                'Add days to the event end date:',
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: c,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Days',
                                                  hintText: '7',
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop<int>(null),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                final int parsed =
                                                    int.tryParse(c.text.trim()) ??
                                                        7;
                                                Navigator.of(context)
                                                    .pop<int>(parsed);
                                              },
                                              child: const Text('Extend'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (days == null || days <= 0) return;
                                    final DateTime newEndsAt =
                                        event.endsAt.add(
                                      Duration(days: days),
                                    );
                                    final r = await ref
                                        .read(communityRepositoryProvider)
                                        .extendEvent(
                                          organizerActionUserId,
                                          event.id,
                                          newEndsAt,
                                        );
                                    if (!context.mounted) return;
                                    r.fold(
                                      (Failure f) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              f.message ?? 'Extend failed',
                                            ),
                                          ),
                                        );
                                      },
                                      (_) {
                                        ref.invalidate(eventByIdProvider(
                                          eventId,
                                        ));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Event extended'),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: const Text('Extend Event'),
                                ),
                                const SizedBox(height: 10),
                              ],
                              OutlinedButton(
                                onPressed: () async {
                                  final bool? ok = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete event?'),
                                        content: const Text(
                                          'This removes the event from listings and the event leaderboard.',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (ok != true) return;
                                  final r = await ref
                                      .read(communityRepositoryProvider)
                                      .deleteEvent(organizerActionUserId, event.id);
                                  if (!context.mounted) return;
                                  r.fold(
                                    (Failure f) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            f.message ?? 'Delete failed',
                                          ),
                                        ),
                                      );
                                    },
                                    (_) {
                                      ref.invalidate(upcomingEventsProvider);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Event deleted'),
                                        ),
                                      );
                                      context.go('/community/events');
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                    color: AppColors.error.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: const Text('Delete Event'),
                              ),
                            ],
                          )
                        : joined
                            ? OutlinedButton(
                                onPressed: null,
                                child: Text(
                                  "You're in ✓",
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              )
                            : FilledButton(
                                onPressed: myId == null
                                    ? null
                                    : () async {
                                        final r = await ref
                                            .read(communityRepositoryProvider)
                                            .joinEvent(myId, event.id);
                                        r.fold(
                                          (Failure f) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  f.message ??
                                                      'Could not join',
                                                ),
                                              ),
                                            );
                                          },
                                          (_) {
                                            ref.invalidate(eventByIdProvider(
                                              eventId,
                                            ));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Joined · +${event.rewardFc} FC when you complete',
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(
                                  'Join Event · +${event.rewardFc} FC',
                                  style: AppTextStyles.button,
                                ),
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(String k, String v) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(k, style: AppTextStyles.bodySmall),
          Text(v, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _RouteHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AppColors.surfaceContainer.withValues(alpha: 0.95),
          AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        ],
      ).createShader(r);
    canvas.drawRect(r, bg);

    final Path path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.35,
        size.width * 0.82,
        size.height * 0.55,
      );
    final Paint line = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
