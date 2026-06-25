import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../domain/entities/breathing_pattern.dart';
import '../providers/mental_wellbeing_providers.dart';
import '../widgets/breathing_circle.dart';

class _Phase {
  _Phase(this.label, this.seconds);

  final String label;
  final int seconds;
}

List<_Phase> _phasesFor(BreathingPattern p) {
  final List<int> s = p.phaseSeconds;
  const List<String> labels = <String>['Inhale', 'Hold', 'Exhale', 'Hold'];
  final List<_Phase> out = <_Phase>[];
  for (int i = 0; i < 4; i++) {
    if (s[i] > 0) {
      out.add(_Phase(labels[i], s[i]));
    }
  }
  return out;
}

/// Guided breathing cycles with summary.
class BreathingSessionScreen extends ConsumerStatefulWidget {
  const BreathingSessionScreen({super.key, required this.pattern});

  final BreathingPattern pattern;

  @override
  ConsumerState<BreathingSessionScreen> createState() =>
      _BreathingSessionScreenState();
}

class _BreathingSessionScreenState
    extends ConsumerState<BreathingSessionScreen> {
  late final List<_Phase> _phases;
  Timer? _timer;
  int _phaseIndex = 0;
  int _secLeft = 0;
  int _cycle = 1;
  double _scale = 0.65;
  bool _stopped = false;
  String? _summary;

  @override
  void initState() {
    super.initState();
    _phases = _phasesFor(widget.pattern);
    _secLeft = _phases.first.seconds;
    _tickScale();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (_stopped || _summary != null) {
      return;
    }
    setState(() {
      if (_secLeft > 1) {
        _secLeft--;
      } else {
        _advancePhase();
      }
      _tickScale();
    });
  }

  void _advancePhase() {
    if (_phaseIndex < _phases.length - 1) {
      _phaseIndex++;
      _secLeft = _phases[_phaseIndex].seconds;
    } else {
      _phaseIndex = 0;
      _secLeft = _phases[0].seconds;
      _cycle++;
      if (_cycle > widget.pattern.cyclesTarget) {
        _finish(completed: true);
      }
    }
  }

  void _tickScale() {
    final _Phase ph = _phases[_phaseIndex];
    final int total = ph.seconds;
    final int elapsed = total - _secLeft;
    final double p = total <= 0 ? 1.0 : elapsed / total;
    if (ph.label == 'Inhale') {
      _scale = 0.65 + 0.35 * p;
    } else if (ph.label == 'Exhale') {
      _scale = 1.0 - 0.35 * p;
    } else if (ph.label == 'Hold') {
      final bool afterExhale =
          _phaseIndex > 0 && _phases[_phaseIndex - 1].label == 'Exhale';
      _scale = afterExhale ? 0.65 : 1.0;
    } else {
      _scale = 0.8;
    }
  }

  void _finish({required bool completed}) {
    _timer?.cancel();
    _stopped = true;
    final int done = completed ? widget.pattern.cyclesTarget : _cycle - 1;
    final String msg = 'Completed $done cycles · ${widget.pattern.title}';
    ref.read(breathingSessionLogProvider.notifier).record(msg);
    setState(() => _summary = msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_summary != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Summary', style: AppTextStyles.headlineMedium),
          backgroundColor: AppColors.surfaceContainer,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(_summary!, style: AppTextStyles.bodyLarge),
              const Spacer(),
              NeonOutlineButton(
                label: 'Back to Wellbeing',
                onPressed: () => context.go('/mental'),
              ),
            ],
          ),
        ),
      );
    }

    final _Phase ph = _phases[_phaseIndex];
    final int total = ph.seconds;
    final double phaseP = total <= 0 ? 1.0 : (total - _secLeft) / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.pattern.title, style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Text(
            'Cycle $_cycle of ${widget.pattern.cyclesTarget}',
            style: AppTextStyles.labelSmall,
          ),
          const Spacer(),
          BreathingCircle(
            scale: _scale,
            phaseLabel: ph.label,
            secondsLeft: _secLeft,
            phaseProgress: phaseP.clamp(0.0, 1.0),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _finish(completed: false),
            child: Text('Stop', style: AppTextStyles.labelLarge),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
