import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts plain text from a PDF for local lab parsing (no network).
String extractTextFromPdfBytes(Uint8List bytes) {
  try {
    final PdfDocument doc = PdfDocument(inputBytes: bytes);
    final String text = PdfTextExtractor(doc).extractText();
    doc.dispose();
    return text;
  } catch (_) {
    return '';
  }
}
