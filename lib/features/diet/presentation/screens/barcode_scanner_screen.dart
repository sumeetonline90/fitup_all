import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal_type.dart';
import '../providers/diet_providers.dart';

/// Barcode scan → repository / Open Food Facts lookup via [barcodeScanProvider].
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key, required this.mealType});

  final MealType mealType;

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    torchEnabled: false,
  );
  bool _busy = false;
  Food? _result;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCamera());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ensureCamera() async {
    final PermissionStatus s = await Permission.camera.request();
    if (!s.isGranted && mounted) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceContainer,
            title: Text('Camera access', style: AppTextStyles.headlineMedium),
            content: Text(
              'Fitup needs the camera to scan barcodes. You can enable it in system settings.',
              style: AppTextStyles.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _result != null) {
      return;
    }
    final String? raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) {
      return;
    }
    final String barcode = raw.replaceAll(RegExp(r'\s'), '');
    setState(() {
      _busy = true;
      _notFound = false;
    });
    final Food? food =
        await ref.read(barcodeScanProvider(barcode).future);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (food != null) {
        _result = food;
      } else {
        _notFound = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('Scan', style: AppTextStyles.headlineMedium),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Barcode scanning is not available on web in this build.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: AppColors.onSurface),
                  ),
                  IconButton(
                    tooltip: 'Toggle flash',
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(
                      Icons.flash_on_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text('Looking up…', style: AppTextStyles.bodyLarge),
                    ],
                  ),
                ),
              ),
            ),
          if (_result != null) _buildResultSheet(context),
          if (_notFound) _buildNotFound(context),
        ],
      ),
    );
  }

  Widget _buildResultSheet(BuildContext context) {
    final Food f = _result!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(f.name, style: AppTextStyles.headlineMedium),
              if (f.brand != null) Text(f.brand!, style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Text(
                '${f.caloriesPer100g.round()} kcal / 100g',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.pop<Food>(f),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.background,
                ),
                child: Text('Add to ${widget.mealType.label}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Food not found', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Try another barcode or add manually from the meal log.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _notFound = false;
                    _busy = false;
                  });
                },
                child: const Text('Scan again'),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.72,
            height: 140,
          ),
          const Radius.circular(12),
        ),
      );
    final Path mask = Path.combine(PathOperation.difference, path, hole);
    canvas.drawPath(
      mask,
      Paint()..color = AppColors.background.withValues(alpha: 0.55),
    );
    final Paint border = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.72,
          height: 140,
        ),
        const Radius.circular(12),
      ),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
