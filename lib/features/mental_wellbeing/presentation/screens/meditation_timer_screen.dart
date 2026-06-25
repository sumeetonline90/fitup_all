import 'dart:async';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/meditation_sound.dart';
import '../providers/mental_wellbeing_providers.dart';

const List<String> _cues = <String>[
  'Focus on your breath.',
  'Let thoughts pass like clouds.',
  'Return to stillness.',
];

/// Passed via [GoRouterState.extra] for `/mental/meditation/timer`.
class MeditationTimerRouteExtra {
  const MeditationTimerRouteExtra({
    required this.totalSeconds,
    required this.sound,
  });

  final int totalSeconds;
  final MeditationSound sound;
}

/// Countdown meditation with optional looping ambient audio.
class MeditationTimerScreen extends ConsumerStatefulWidget {
  const MeditationTimerScreen({
    super.key,
    required this.totalSeconds,
    required this.sound,
  });

  final int totalSeconds;
  final MeditationSound sound;

  @override
  ConsumerState<MeditationTimerScreen> createState() =>
      _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends ConsumerState<MeditationTimerScreen>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _tick;
  late final AnimationController _pulse;
  int _cueIndex = 0;
  Timer? _cueRotate;
  AudioPlayer? _player;
  bool _audioReady = false;
  String? _audioHint;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _startAudio();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _tick?.cancel();
        unawaited(_complete());
      }
    });
    _cueRotate = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _cueIndex = (_cueIndex + 1) % _cues.length);
      }
    });
  }

  Future<void> _startAudio() async {
    if (widget.sound == MeditationSound.silent) {
      setState(() {
        _audioReady = false;
        _audioHint = 'Silent mode';
      });
      return;
    }
    try {
      final AudioPlayer p = AudioPlayer();
      _player = p;
      await p.setLoopMode(LoopMode.one);
      await p.setVolume(0.55);
      final String? path = widget.sound.assetPath;
      bool loaded = false;
      if (path != null) {
        try {
          await p.setAsset(path);
          loaded = true;
        } catch (_) {}
      }
      if (!loaded) {
        final String? url = widget.sound.fallbackUrl;
        if (url != null) {
          final List<ConnectivityResult> conn =
              await Connectivity().checkConnectivity();
          final bool isOffline = conn.isEmpty ||
              conn.every(
                (ConnectivityResult r) => r == ConnectivityResult.none,
              );
          if (isOffline) {
            if (mounted) {
              setState(() {
                _audioReady = false;
                _audioHint = '${widget.sound.label} offline — silent mode';
              });
            }
            return;
          }

          await p.setUrl(url);
          loaded = true;
        }
      }
      if (!loaded) {
        setState(() {
          _audioReady = false;
          _audioHint = '${widget.sound.label} unavailable — silent mode';
        });
        return;
      }
      await p.play();
      if (mounted) {
        setState(() {
          _audioReady = true;
          _audioHint = '${widget.sound.label} playing';
        });
      }
    } catch (_) {
      _player?.dispose();
      _player = null;
      if (mounted) {
        setState(() {
          _audioReady = false;
          _audioHint = '${widget.sound.label} unavailable — silent mode';
        });
      }
    }
  }

  Future<void> _complete() async {
    _cueRotate?.cancel();
    _pulse.stop();
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    if (!mounted) {
      return;
    }
    final int mins = (widget.totalSeconds / 60).ceil();
    ref
        .read(meditationSessionLogProvider.notifier)
        .record('Meditation $mins min completed');
    context.go('/mental/meditation/complete?minutes=$mins');
  }

  void _endEarly() {
    _tick?.cancel();
    _cueRotate?.cancel();
    unawaited(_player?.stop());
    unawaited(_player?.dispose());
    _player = null;
    final int mins = ((widget.totalSeconds - _remaining) / 60).ceil().clamp(
      1,
      999,
    );
    ref
        .read(meditationSessionLogProvider.notifier)
        .record('Meditation ended early (~$mins min)');
    if (mounted) {
      context.go('/mental');
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _cueRotate?.cancel();
    _pulse.dispose();
    unawaited(_player?.dispose());
    super.dispose();
  }

  String _fmt(int sec) {
    final int m = sec ~/ 60;
    final int s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(painter: _BreathWavesPainter(_pulse.value));
            },
          ),
          CustomPaint(painter: _ParticlesPainter()),
          AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, Widget? child) {
              return Center(
                child: Opacity(
                  opacity: 0.12 + 0.08 * _pulse.value,
                  child: Container(
                    width: 220 + 40 * _pulse.value,
                    height: 220 + 40 * _pulse.value,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 48),
                Text(
                  _fmt(_remaining),
                  style: AppTextStyles.headlineLarge.copyWith(fontSize: 56),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (_audioReady
                                ? AppColors.secondary
                                : AppColors.outlineVariant)
                            .withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _audioHint ?? 'Preparing audio…',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _audioReady
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _cues[_cueIndex],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _endEarly,
                  child: Text('End Session', style: AppTextStyles.labelLarge),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random r = math.Random(42);
    final Paint p = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.08);
    for (int i = 0; i < 40; i++) {
      final double x = r.nextDouble() * size.width;
      final double y = r.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.2 + r.nextDouble(), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BreathWavesPainter extends CustomPainter {
  _BreathWavesPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double base = size.shortestSide * 0.16;
    for (int i = 0; i < 4; i++) {
      final double phase = (t + (i * 0.2)) % 1.0;
      final double r = base + (size.shortestSide * 0.24 * phase);
      final double alpha = (0.24 - phase * 0.20).clamp(0.03, 0.24);
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppColors.secondary.withValues(alpha: alpha);
      canvas.drawCircle(c, r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BreathWavesPainter oldDelegate) =>
      oldDelegate.t != t;
}
