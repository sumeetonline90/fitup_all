import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/community_event.dart';
import '../providers/community_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _maxParticipants = TextEditingController(text: '20');
  final TextEditingController _reward = TextEditingController(text: '100');
  final TextEditingController _targetSteps = TextEditingController();
  final TextEditingController _targetDistance = TextEditingController();

  EventType _type = EventType.stepChallenge;
  EventVisibility _visibility = EventVisibility.public;
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 3));

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxParticipants.dispose();
    _reward.dispose();
    _targetSteps.dispose();
    _targetDistance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CommunityEvent?> createState = ref.watch(createEventProvider);
    ref.listen<AsyncValue<CommunityEvent?>>(createEventProvider, (_, AsyncValue<CommunityEvent?> next) {
      next.whenOrNull(
        data: (CommunityEvent? created) async {
          if (created == null || !context.mounted) return;
          await Clipboard.setData(ClipboardData(text: created.eventCode));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event created. Code copied: ${created.eventCode}')),
          );
          context.pop();
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: <Widget>[
            Text(
              'Build a neon challenge room for your community.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              glowColor: AppColors.secondary,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Event title'),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<EventType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Event type'),
                    items: EventType.values
                        .map(
                          (EventType e) => DropdownMenuItem<EventType>(
                            value: e,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (EventType? v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<EventVisibility>(
                    segments: const <ButtonSegment<EventVisibility>>[
                      ButtonSegment<EventVisibility>(
                        value: EventVisibility.public,
                        label: Text('Public'),
                      ),
                      ButtonSegment<EventVisibility>(
                        value: EventVisibility.private,
                        label: Text('Private'),
                      ),
                    ],
                    selected: <EventVisibility>{_visibility},
                    onSelectionChanged: (Set<EventVisibility> value) {
                      setState(() => _visibility = value.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: <Widget>[
                  _DateRow(
                    label: 'Starts',
                    value: _start,
                    button: 'Pick Start Date',
                    onTap: () async {
                      final DateTime? d = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: _start,
                      );
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DateRow(
                    label: 'Ends',
                    value: _end,
                    button: 'Pick End Date',
                    onTap: () async {
                      final DateTime? d = await showDatePicker(
                        context: context,
                        firstDate: _start,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: _end,
                      );
                      if (d != null) setState(() => _end = d);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _maxParticipants,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max participants'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reward,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reward FC'),
                  ),
                  if (_type == EventType.stepChallenge) ...<Widget>[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetSteps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target steps'),
                    ),
                  ],
                  if (_type == EventType.walkingChallenge) ...<Widget>[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetDistance,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Target distance (km)'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            NeonButton(
              label: createState.isLoading ? 'Creating...' : 'Create Event',
              onPressed: createState.isLoading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      await ref.read(createEventProvider.notifier).create(
                            CreateEventInput(
                              title: _title.text,
                              description: _description.text,
                              type: _type,
                              visibility: _visibility,
                              startsAt: _start,
                              endsAt: _end,
                              maxParticipants:
                                  int.tryParse(_maxParticipants.text) ?? 20,
                              fitcoinsReward: int.tryParse(_reward.text) ?? 100,
                              targetSteps: int.tryParse(_targetSteps.text),
                              targetDistanceKm:
                                  double.tryParse(_targetDistance.text),
                            ),
                          );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.button,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$label: ${value.toLocal().toString().split(' ').first}',
            style: AppTextStyles.bodySmall,
          ),
        ),
        TextButton(onPressed: onTap, child: Text(button)),
      ],
    );
  }
}
