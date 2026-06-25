import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

/// One survey question with Likert [RadioListTile] options.
class SurveyQuestionCard extends StatelessWidget {
  const SurveyQuestionCard({
    super.key,
    required this.question,
    required this.optionLabels,
    required this.groupValue,
    required this.onChanged,
  });

  final String question;
  final List<String> optionLabels;
  final int? groupValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: RadioGroup<int>(
        groupValue: groupValue,
        onChanged: (int? v) {
          if (v != null) {
            onChanged(v);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              question,
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < optionLabels.length; i++)
              RadioListTile<int>(
                dense: true,
                value: i,
                title: Text(optionLabels[i], style: AppTextStyles.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}
