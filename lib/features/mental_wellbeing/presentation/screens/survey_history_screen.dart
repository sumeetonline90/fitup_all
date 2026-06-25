import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/survey_type.dart';
import '../providers/mental_wellbeing_providers.dart';

/// Past survey submissions.
class SurveyHistoryScreen extends ConsumerWidget {
  const SurveyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SurveyResultUi>> async = ref.watch(
      surveyHistoryProvider,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Survey history', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => Center(
          child: Text(
            'Could not load history.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (List<SurveyResultUi> list) => list.isEmpty
            ? Center(
                child: Text('No surveys yet.', style: AppTextStyles.bodyMedium),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int i) {
                  final SurveyResultUi r = list[i];
                  return ListTile(
                    tileColor: AppColors.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(_name(r.type), style: AppTextStyles.bodyLarge),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(r.takenAt),
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: Text(
                      '${r.score}/${surveyMaxScore(r.type)}',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  static String _name(SurveyType t) => switch (t) {
    SurveyType.phq9 => 'PHQ-9',
    SurveyType.gad7 => 'GAD-7',
    SurveyType.pss10 => 'PSS-10',
  };
}
