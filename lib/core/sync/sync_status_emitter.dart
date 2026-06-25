import 'dart:async';

/// Cross-layer sync messages (e.g. profile saved locally, pending remote).
/// [FitupApp] listens and shows a [SnackBar] — keeps data layer free of Flutter imports.
class SyncStatusEmitter {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get messages => _controller.stream;

  void emitProfilePendingLocalSync() {
    if (!_controller.isClosed) {
      _controller.add(
        'Saved locally — will sync when you are back online',
      );
    }
  }

  void dispose() {
    _controller.close();
  }
}
