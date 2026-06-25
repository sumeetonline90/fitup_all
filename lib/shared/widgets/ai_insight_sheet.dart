import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/models/ai_insight.dart';
import 'shimmer_loading.dart';

/// Opens the reusable Fitup AI bottom sheet.
Future<void> showAiInsightSheet(
  BuildContext context, {
  required String module,
  AiInsight? insight,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => AiInsightSheet(
      module: module,
      insight: insight,
    ),
  );
}

/// Shared AI insight UI for Activity, Diet, Workout, etc.
class AiInsightSheet extends StatefulWidget {
  const AiInsightSheet({
    super.key,
    required this.module,
    this.insight,
  });

  final String module;
  final AiInsight? insight;

  @override
  State<AiInsightSheet> createState() => _AiInsightSheetState();
}

class _AiInsightSheetState extends State<AiInsightSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final TextEditingController _question = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
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
              const SizedBox(height: 20),
              Center(child: _PulsingOrb(controller: _pulse)),
              const SizedBox(height: 12),
              Text(
                'Fitup AI',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.insight?.disclaimer ??
                    'This is not medical advice. Consult a professional for health decisions.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (widget.insight == null) ..._loadingBody() else ..._contentBody(widget.insight!),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Ask AI about this'),
                onPressed: () {
                  final String m = widget.module;
                  Navigator.of(context).pop();
                  context.push(
                    '/insights/chat',
                    extra: <String, String>{'moduleContext': m},
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _question,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: AppTextStyles.bodyMedium,
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _loadingBody() {
    return <Widget>[
      const ShimmerLoading(height: 24),
      const SizedBox(height: 12),
      const ShimmerLoading(height: 16),
      const SizedBox(height: 8),
      const ShimmerLoading(height: 16),
      const SizedBox(height: 8),
      const ShimmerLoading(height: 16),
      const SizedBox(height: 20),
      const ShimmerLoading(height: 14),
      const SizedBox(height: 8),
      const ShimmerLoading(height: 14),
    ];
  }

  List<Widget> _contentBody(AiInsight insight) {
    return <Widget>[
      Text(
        insight.summary,
        style: AppTextStyles.headlineMedium.copyWith(fontSize: 22),
      ),
      const SizedBox(height: 16),
      ...insight.details.map(
        (String d) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('• ', style: AppTextStyles.bodyLarge),
              Expanded(child: Text(d, style: AppTextStyles.bodyLarge)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text('Suggestions', style: AppTextStyles.labelSmall),
      const SizedBox(height: 8),
      ...insight.suggestions.map(
        (String s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(s, style: AppTextStyles.bodyMedium)),
            ],
          ),
        ),
      ),
    ];
  }
}

class _PulsingOrb extends StatelessWidget {
  const _PulsingOrb({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double t = controller.value;
        final double size = 56 + 14 * t;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.35 + 0.25 * t),
                blurRadius: 22 + 18 * t,
                spreadRadius: 2 * t,
              ),
            ],
            gradient: RadialGradient(
              colors: <Color>[
                AppColors.secondary.withValues(alpha: 0.95),
                AppColors.secondary.withValues(alpha: 0.15),
              ],
            ),
          ),
        );
      },
    );
  }
}
