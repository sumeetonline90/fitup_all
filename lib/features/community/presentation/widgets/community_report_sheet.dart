import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/report_reason.dart';

/// Bottom sheet: pick [ReportReason] and submit.
class CommunityReportSheet extends StatefulWidget {
  const CommunityReportSheet({super.key, required this.onSubmit});

  final void Function(ReportReason reason) onSubmit;

  @override
  State<CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<CommunityReportSheet> {
  ReportReason _reason = ReportReason.other;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Report user', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'Tell us what’s wrong. This is for moderation review only — not an emergency service.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportReason.values.map((ReportReason r) {
              final bool sel = _reason == r;
              return ChoiceChip(
                label: Text(_label(r), style: AppTextStyles.labelSmall),
                selected: sel,
                onSelected: (_) => setState(() => _reason = r),
                selectedColor: AppColors.secondary.withValues(alpha: 0.3),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSubmit(_reason);
            },
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }

  static String _label(ReportReason r) => switch (r) {
        ReportReason.spam => 'Spam',
        ReportReason.harassment => 'Harassment',
        ReportReason.inappropriateContent => 'Inappropriate',
        ReportReason.other => 'Other',
      };
}
