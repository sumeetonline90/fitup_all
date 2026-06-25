import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/diet_providers.dart';

/// Bottom sheet: AI diet analysis from [dietInsightForProvider] (Gemini Flash).
Future<void> showAiDietInsightSheet(
  BuildContext context, {
  required String dateKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => AiDietInsightSheet(dateKey: dateKey),
  );
}

class AiDietInsightSheet extends ConsumerStatefulWidget {
  const AiDietInsightSheet({super.key, required this.dateKey});

  final String dateKey;

  @override
  ConsumerState<AiDietInsightSheet> createState() => _AiDietInsightSheetState();
}

class _AiDietInsightSheetState extends ConsumerState<AiDietInsightSheet> {
  Future<void> _refresh() async {
    ref.invalidate(dietInsightForProvider(widget.dateKey));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<String> insight =
        ref.watch(dietInsightForProvider(widget.dateKey));
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
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
              Row(
                children: <Widget>[
                  const Icon(Icons.auto_awesome, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Diet Analysis',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh analysis',
                    onPressed: insight.isLoading ? null : _refresh,
                    icon: Icon(
                      Icons.refresh,
                      color: insight.isLoading
                          ? AppColors.onSurfaceVariant
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              insight.when(
                loading: () => const _LoadingBody(),
                error: (Object e, StackTrace st) => Text(
                  'Could not load insight: $e',
                  style: AppTextStyles.bodyMedium,
                ),
                data: (String text) => _LoadedBody(text: text),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Ask AI about this'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/insights/chat',
                    extra: <String, String>{'moduleContext': 'Diet'},
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'AI suggestions are not medical advice.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShimmerLoading(height: 20),
        SizedBox(height: 10),
        ShimmerLoading(height: 14),
        SizedBox(height: 8),
        ShimmerLoading(height: 14),
        SizedBox(height: 20),
        ShimmerLoading(height: 18),
        SizedBox(height: 10),
        ShimmerLoading(height: 14),
      ],
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyLarge,
    );
  }
}
