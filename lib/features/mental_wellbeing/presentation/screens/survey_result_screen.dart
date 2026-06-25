import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../domain/entities/survey_type.dart';
import '../survey_content.dart';
import 'survey_screen.dart';

/// Score + disclaimer + tips after a survey.
class SurveyResultScreen extends StatefulWidget {
  const SurveyResultScreen({super.key, required this.extra});

  final SurveyResultExtra extra;

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen> {
  String _aiLine = '';
  bool _aiLoading = false;
  bool _aiGenerated = false;

  Future<void> _loadAi() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    setState(() {
      _aiLoading = false;
      _aiGenerated = true;
      _aiLine =
          'Thanks for checking in. Small steps — sleep, movement, and reaching '
          'out to someone you trust — often help. This is supportive guidance '
          'only, not therapy.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final SurveyResultExtra e = widget.extra;
    final String label = severityLabel(e.type, e.score);
    final Color sevColor = _severityColor(e.type, e.score);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Results', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sevColor.withValues(alpha: 0.2),
                border: Border.all(color: sevColor, width: 2),
              ),
              child: Center(
                child: Text(
                  '${e.score}/${e.maxScore}',
                  style: AppTextStyles.headlineLarge.copyWith(fontSize: 26),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(color: sevColor),
          ),
          const SizedBox(height: 12),
          Text(
            'This is a self-assessment tool, not a clinical diagnosis.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text('AI Insight', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_aiLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_aiGenerated)
                  Text(_aiLine, style: AppTextStyles.bodyMedium)
                else
                  Text(
                    'Tap below to generate your AI insight for this survey result.',
                    style: AppTextStyles.bodyMedium,
                  ),
                const SizedBox(height: 12),
                NeonOutlineButton(
                  label: _aiGenerated ? 'Regenerate AI Insight' : 'Generate AI Insight',
                  onPressed: () {
                    if (_aiLoading) {
                      return;
                    }
                    _loadAi();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text('What can I do?', style: AppTextStyles.headlineMedium),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(_tipsBlock(), style: AppTextStyles.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeonOutlineButton(
            label: 'See History',
            onPressed: () => context.push('/mental/survey-history'),
          ),
          const SizedBox(height: 10),
          NeonOutlineButton(
            label: 'Back to Wellbeing',
            onPressed: () => context.go('/mental'),
          ),
        ],
      ),
    );
  }

  Color _severityColor(SurveyType type, int score) {
    final String l = severityLabel(type, score).toLowerCase();
    if (l.contains('severe') || l.contains('high')) {
      return AppColors.error;
    }
    if (l.contains('moderate')) {
      return AppColors.primary;
    }
    return AppColors.secondary;
  }

  String _tipsBlock() {
    return '• Keep a regular sleep schedule.\n'
        '• Move gently most days (walk, stretch).\n'
        '• Share how you feel with someone you trust.\n'
        '• If you feel unsafe or in crisis, contact local emergency services '
        'or a crisis line immediately.';
  }
}
