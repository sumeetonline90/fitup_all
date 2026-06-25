import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/survey_result.dart';
import '../../domain/entities/survey_type.dart';
import '../providers/mental_wellbeing_providers.dart';
import '../survey_content.dart';
import '../widgets/survey_question_card.dart';

/// PHQ-9 / GAD-7 / PSS-10 flow.
class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key, required this.type});

  final SurveyType type;

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  late final PageController _page;
  late final List<SurveyQuestion> _questions;
  late final List<String> _labels;
  late final List<int?> _answers;
  int _index = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _questions = questionsFor(widget.type);
    _labels = widget.type == SurveyType.pss10
        ? likert04Labels()
        : likert03Labels();
    _answers = List<int?>.filled(_questions.length, null);
    _page = PageController();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _onPick(int value) async {
    setState(() => _answers[_index] = value);
    if (_index < _questions.length - 1) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      setState(() => _index++);
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    if (_answers.any((int? a) => a == null) || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    if (!mounted) {
      return;
    }
    final List<int> raw = _answers.map((int? a) => a!).toList();
    try {
      final SurveyNotifier notifier = ref.read(surveyProvider.notifier);
      notifier.clearAnswers();
      for (int i = 0; i < raw.length; i++) {
        notifier.answerQuestion(i, raw[i]);
      }
      final SurveyResult saved = await notifier.submitSurvey(widget.type);
      if (!mounted) {
        return;
      }
      context.pushReplacement(
        '/mental/survey/result',
        extra: SurveyResultExtra(
          type: widget.type,
          score: saved.totalScore,
          maxScore: surveyMaxScore(widget.type),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save survey. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int n = _questions.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title(widget.type), style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Question ${_index + 1} of $n',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_index + 1) / n,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: n,
              itemBuilder: (BuildContext context, int i) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SurveyQuestionCard(
                    question: _questions[i].text,
                    optionLabels: _labels,
                    groupValue: _answers[i],
                    onChanged: i == _index ? _onPick : (_) {},
                  ),
                );
              },
            ),
          ),
          if (_submitting)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: NeonButton(
                label: _index < n - 1 ? 'Next' : 'Submit',
                onPressed: _answers[_index] == null
                    ? null
                    : () async {
                        if (_index < n - 1) {
                          await _page.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                          setState(() => _index++);
                        } else {
                          await _submit();
                        }
                      },
              ),
            ),
        ],
      ),
    );
  }

  String _title(SurveyType t) => switch (t) {
    SurveyType.phq9 => 'PHQ-9',
    SurveyType.gad7 => 'GAD-7',
    SurveyType.pss10 => 'PSS-10',
  };
}

/// Passed to [SurveyResultScreen] via GoRouter [extra].
class SurveyResultExtra {
  const SurveyResultExtra({
    required this.type,
    required this.score,
    required this.maxScore,
  });

  final SurveyType type;
  final int score;
  final int maxScore;
}
