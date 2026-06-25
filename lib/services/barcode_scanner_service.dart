import 'package:mobile_scanner/mobile_scanner.dart';

/// Wraps [MobileScannerController] — attach [MobileScanner] in UI and listen to [captures].
class BarcodeScannerService {
  BarcodeScannerService() : controller = MobileScannerController();

  final MobileScannerController controller;

  Stream<BarcodeCapture> get captures => controller.barcodes;

  Future<void> dispose() async {
    await controller.dispose();
  }
}
