import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/community_event.dart';
import '../providers/community_providers.dart';

class CommunityEventsListScreen extends ConsumerWidget {
  const CommunityEventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CommunityEvent>> async = ref.watch(
      upcomingEventsProvider,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Events',
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  e is Failure
                      ? (e.message ?? 'Error')
                      : 'Could not load events',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(upcomingEventsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (List<CommunityEvent> events) {
          final Widget aiPlanGuideCard = GlassCard(
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'AI Plan Guide',
                style: AppTextStyles.labelLarge,
              ),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'How plans + AI nudges work: holistic plan is generated first (with start/end dates), '
                    'then each module plan can be amended. Only one holistic plan is active at a time. '
                    'The app checks your daily adherence against the active targets and may show supportive suggestions. '
                    'This is not medical advice.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          );
          if (events.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                aiPlanGuideCard,
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No upcoming events',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length + 1,
            itemBuilder: (BuildContext context, int i) {
              if (i == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: aiPlanGuideCard,
                );
              }
              final CommunityEvent e = events[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push('/community/events/${e.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          e.title,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.MMMd().add_jm().format(e.startsAt),
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(e.locationLabel, style: AppTextStyles.bodySmall),
                        Text(
                          '+${e.rewardFc} FC · ${e.participantCount} joined',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
