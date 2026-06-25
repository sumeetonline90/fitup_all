import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/community_event.dart';
import '../providers/community_providers.dart';

class EventSearchScreen extends ConsumerStatefulWidget {
  const EventSearchScreen({super.key});

  @override
  ConsumerState<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends ConsumerState<EventSearchScreen> {
  final TextEditingController _code = TextEditingController();
  String _submitted = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CommunityEvent>> publicEvents = ref.watch(upcomingEventsProvider);
    final AsyncValue<CommunityEvent>? lookup = _submitted.isEmpty
        ? null
        : ref.watch(eventSearchByCodeProvider(_submitted));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Search Events')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: <Widget>[
          Text(
            'Discover public events or unlock private ones with exact code.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            glowColor: AppColors.secondary,
            child: TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Enter event code',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _submitted = _code.text.trim().toUpperCase()),
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (String value) =>
                  setState(() => _submitted = value.trim().toUpperCase()),
            ),
          ),
          const SizedBox(height: 12),
          if (lookup != null)
            lookup.when(
              data: (CommunityEvent e) => GlassCard(
                glowColor: e.isPublic ? AppColors.secondary : AppColors.tertiary,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.title),
                  subtitle: Text(
                    'Code: ${e.eventCode} • ${e.isPublic ? 'Public' : 'Private'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/community/events/${e.id}'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Text(
                e is Failure ? (e.message ?? 'Not found') : 'Event not found',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          const SizedBox(height: 20),
          Text('Public Events', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          publicEvents.when(
            data: (List<CommunityEvent> list) => Column(
              children: list
                  .map(
                    (CommunityEvent e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.title),
                          subtitle: Text('Code: ${e.eventCode}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.push('/community/events/${e.id}'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Unable to load public events'),
          ),
        ],
      ),
    );
  }
}
