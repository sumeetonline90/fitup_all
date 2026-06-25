import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failures.dart' show Failure, ValidationFailure;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/vital_type.dart';
import '../../data/lab_text_pre_parser.dart';
import '../../data/pdf_text_extractor.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../health_ui_models.dart';
import '../providers/health_providers.dart';
import '../widgets/lab_scan_result_tile.dart';

/// In-memory cache: PDF content hash -> extracted plain text (dedup / reuse).
final Map<String, String> _labPdfTextCache = <String, String>{};

/// Upload / camera lab report → local parse (PDF) → AI detect → save vitals.
class LabScanScreen extends ConsumerStatefulWidget {
  const LabScanScreen({super.key});

  @override
  ConsumerState<LabScanScreen> createState() => _LabScanScreenState();
}

class _LabScanScreenState extends ConsumerState<LabScanScreen> {
  final ImagePicker _picker = ImagePicker();
  _LabSource _source = _LabSource.image;
  XFile? _image;
  Uint8List? _imageBytes;
  String? _pdfName;
  Uint8List? _pdfBytes;
  String? _pdfExtractedText;
  int _localReadingCount = 0;
  bool _loading = false;
  String? _error;
  List<ExtractedVitalRow>? _rows;

  Future<void> _pick(ImageSource src) async {
    setState(() {
      _error = null;
      _rows = null;
      _pdfName = null;
      _pdfBytes = null;
      _pdfExtractedText = null;
      _localReadingCount = 0;
      _source = _LabSource.image;
    });
    final XFile? f = await _picker.pickImage(source: src, imageQuality: 85);
    if (f != null) {
      final Uint8List bytes = await f.readAsBytes();
      setState(() {
        _image = f;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickPdf() async {
    setState(() {
      _error = null;
      _rows = null;
      _image = null;
      _source = _LabSource.pdf;
      _pdfExtractedText = null;
      _localReadingCount = 0;
    });
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'Could not read PDF bytes.');
      return;
    }
    final String hash = sha256.convert(bytes).toString();
    String? cached = _labPdfTextCache[hash];
    if (cached == null) {
      cached = extractTextFromPdfBytes(bytes).trim();
      if (cached.isNotEmpty) {
        _labPdfTextCache[hash] = cached;
      }
    }
    int localCount = 0;
    if (cached.isNotEmpty) {
      localCount = preParseLabText(cached).length;
    }
    setState(() {
      _pdfBytes = bytes;
      _pdfName = file.name;
      _pdfExtractedText = cached;
      _localReadingCount = localCount;
    });
  }

  Future<void> _runAiDetect() async {
    final XFile? img = _image;
    final Uint8List? pdf = _pdfBytes;
    if (img == null && pdf == null) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rows = null;
    });
    try {
      final Either<Failure, List<ExtractedVitalRow>> result = switch (_source) {
        _LabSource.pdf when pdf != null => await _runPdfAiPath(pdf),
        _LabSource.image when img != null =>
          await ref
              .read(labScanProvider.notifier)
              .extractLabReportRows(
                Uint8List.fromList(await img.readAsBytes()),
              ),
        _ => const Left<Failure, List<ExtractedVitalRow>>(
          ValidationFailure('No file selected'),
        ),
      };
      if (!mounted) {
        return;
      }
      result.fold(
        (Failure failure) {
          setState(() {
            _loading = false;
            _error = failure.message ?? 'Scan failed';
          });
        },
        (List<ExtractedVitalRow> rows) {
          setState(() {
            _loading = false;
            _rows = rows;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<Either<Failure, List<ExtractedVitalRow>>> _runPdfAiPath(
    Uint8List pdfBytes,
  ) async {
    final String? text = _pdfExtractedText;
    if (text != null && text.isNotEmpty) {
      final List<LocalLabReading> localReadings = preParseLabText(text);
      final Either<Failure, List<ExtractedVitalRow>> textResult = await ref
          .read(labScanProvider.notifier)
          .extractLabReportRowsFromText(text, localReadings: localReadings);
      final List<ExtractedVitalRow>? ok = textResult.fold(
        (Failure _) => null,
        (List<ExtractedVitalRow> rows) => rows,
      );
      if (ok != null) {
        return Right<Failure, List<ExtractedVitalRow>>(ok);
      }
    }
    return ref
        .read(labScanProvider.notifier)
        .extractLabReportRowsFromPdf(pdfBytes);
  }

  Future<void> _save() async {
    final List<ExtractedVitalRow>? r = _rows;
    if (r == null) {
      return;
    }
    final Set<VitalType> counted = <VitalType>{};
    int count = 0;
    for (final ExtractedVitalRow x in r) {
      if (!x.included || x.mappedType == null) {
        continue;
      }
      final VitalType t = x.mappedType!;
      if (counted.contains(t)) {
        continue;
      }
      counted.add(t);
      count++;
    }
    final bool ok = await ref
        .read(labScanProvider.notifier)
        .saveSelectedVitals(r);
    if (!mounted) {
      return;
    }
    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text('Saved', style: AppTextStyles.headlineMedium),
          content: Text(
            count == 1
                ? '1 vital was saved from your lab report.'
                : '$count vitals were saved from your lab report.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/health');
              },
              child: Text('OK', style: AppTextStyles.labelLarge),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Lab scan', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          if (_image == null && !_loading && _rows == null)
            GestureDetector(
              onTap: () => _showSourceSheet(),
              child: CustomPaint(
                painter: _DashedRectPainter(color: AppColors.secondary),
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.upload_file_outlined,
                          size: 48,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload lab report (PDF/image)',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if ((_imageBytes != null || _pdfBytes != null) &&
              _rows == null &&
              !_loading) ...<Widget>[
            if (_source == _LabSource.image && _imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 52,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pdfName ?? 'PDF selected',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (_pdfExtractedText != null &&
                        _pdfExtractedText!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _localReadingCount > 0
                            ? 'Parsed locally — $_localReadingCount readings found'
                            : 'Report text parsed locally',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ] else if (_source == _LabSource.pdf) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Little or no text in PDF — AI will read the file',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: NeonButton(label: 'AI detect', onPressed: _runAiDetect),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _image = null;
                _pdfBytes = null;
                _pdfName = null;
                _pdfExtractedText = null;
              }),
              child: Text(
                'Choose different file',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
          if (_loading) ...<Widget>[
            const SizedBox(height: 48),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              'Gemini AI is reading your report…',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
          if (_error != null) Text(_error!, style: AppTextStyles.bodyMedium),
          if (_rows != null) ...<Widget>[
            Text(
              'We found ${_rows!.length} vitals in your report',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _rows!.length; i++)
              LabScanResultTile(
                row: _rows![i],
                onIncludedChanged: (bool v) {
                  setState(() => _rows![i].included = v);
                },
              ),
            const SizedBox(height: 16),
            NeonOutlineButton(label: 'Save data', onPressed: _save),
          ],
          const SizedBox(height: 24),
          Text(
            'AI extraction may not be 100% accurate. Always verify with your doctor.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Gallery image', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Camera snap', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text('PDF report', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final Paint p = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const double dash = 8;
    double x = r.left;
    while (x < r.right) {
      canvas.drawLine(Offset(x, r.top), Offset(x + dash, r.top), p);
      x += dash * 2;
    }
    double y = r.top;
    while (y < r.bottom) {
      canvas.drawLine(Offset(r.right, y), Offset(r.right, y + dash), p);
      y += dash * 2;
    }
    x = r.right;
    while (x > r.left) {
      canvas.drawLine(Offset(x, r.bottom), Offset(x - dash, r.bottom), p);
      x -= dash * 2;
    }
    y = r.bottom;
    while (y > r.top) {
      canvas.drawLine(Offset(r.left, y), Offset(r.left, y - dash), p);
      y -= dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _LabSource { image, pdf }
