import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_type.dart';
import '../providers/diet_providers.dart';

/// AI photo meal recognition via [mealPhotoAnalysisProvider] (Gemini Flash).
class PhotoMealScreen extends ConsumerStatefulWidget {
  const PhotoMealScreen({super.key, required this.mealType});

  final MealType mealType;

  @override
  ConsumerState<PhotoMealScreen> createState() => _PhotoMealScreenState();
}

class _PhotoMealScreenState extends ConsumerState<PhotoMealScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _loading = false;
  List<_Row> _rows = <_Row>[];
  bool _failed = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? f = await _picker.pickImage(source: source, imageQuality: 82);
      if (f == null) {
        return;
      }
      final Uint8List bytes = await f.readAsBytes();
      setState(() {
        _image = f;
        _imageBytes = bytes;
        _loading = true;
        _failed = false;
        _rows = <_Row>[];
      });
      final result =
          await ref.read(mealPhotoAnalysisProvider(bytes).future);
      if (!mounted) {
        return;
      }
      if (result.items.isEmpty) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      setState(() {
        _loading = false;
        _failed = false;
        _rows = result.items
            .map(
              (FoodItem i) => _Row(item: i, checked: true),
            )
            .toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _toggle(int i, bool? v) {
    setState(() {
      _rows = List<_Row>.from(_rows)
        ..[i] = _rows[i].copyWith(checked: v ?? false);
    });
  }

  void _gramsChanged(int i, double newGrams) {
    final _Row r = _rows[i];
    final FoodItem old = r.item;
    final double ratio =
        old.quantity <= 0 ? 1 : newGrams / old.quantity;
    final FoodItem scaled = old.copyWith(
      quantity: newGrams,
      calories: old.calories * ratio,
      protein: old.protein * ratio,
      carbs: old.carbs * ratio,
      fat: old.fat * ratio,
      fiber: old.fiber != null ? old.fiber! * ratio : null,
    );
    setState(() {
      _rows = List<_Row>.from(_rows)..[i] = r.copyWith(item: scaled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Photo meal', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _image == null ? _pickers() : _analysis(),
    );
  }

  Widget _pickers() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Capture or choose a photo of your meal.',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'Take photo',
            icon: Icons.photo_camera_outlined,
            onPressed: kIsWeb ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, color: AppColors.secondary),
            label: Text(
              'Choose from gallery',
              style: AppTextStyles.button.copyWith(color: AppColors.secondary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysis() {
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Couldn't identify foods. Try again or add manually.",
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'Try again',
              onPressed: () => setState(() {
                _image = null;
                _failed = false;
              }),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (_imageBytes != null)
          Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
          )
        else
          const ColoredBox(
            color: AppColors.surfaceContainerHigh,
            child: Icon(
              Icons.image_outlined,
              size: 120,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        if (_loading)
          ColoredBox(
            color: AppColors.background.withValues(alpha: 0.65),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing your meal...',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        if (!_loading && _rows.isNotEmpty)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: <Widget>[
                  Text('Detected items', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(_rows.length, (int i) {
                    final _Row r = _rows[i];
                    final FoodItem it = r.item;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        CheckboxListTile(
                          value: r.checked,
                          onChanged: (bool? v) => _toggle(i, v),
                          title: Text(it.name, style: AppTextStyles.bodyLarge),
                          subtitle: Text(
                            '${it.calories.round()} kcal · ~${it.quantity.round()} ${it.unit}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: Slider(
                            value: it.quantity.clamp(20, 2000),
                            min: 20,
                            max: 2000,
                            divisions: 99,
                            label: '${it.quantity.round()} ${it.unit}',
                            onChanged: r.checked
                                ? (double v) => _gramsChanged(i, v)
                                : null,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  NeonButton(
                    label:
                        'Add ${_rows.where((_Row e) => e.checked).length} items to ${widget.mealType.label}',
                    onPressed: () {
                      final List<FoodItem> out = <FoodItem>[];
                      for (final _Row r in _rows) {
                        if (r.checked) {
                          out.add(r.item);
                        }
                      }
                      context.pop<List<FoodItem>>(out);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Row {
  const _Row({required this.item, required this.checked});

  final FoodItem item;
  final bool checked;

  _Row copyWith({FoodItem? item, bool? checked}) {
    return _Row(
      item: item ?? this.item,
      checked: checked ?? this.checked,
    );
  }
}
