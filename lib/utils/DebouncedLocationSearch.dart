import 'dart:async';

/// Only the newest address query may update the visible suggestions.
class DebouncedLocationSearch<T> {
  final Future<T> Function(String) fetch;
  final void Function(T?) onResult;
  final void Function(Object)? onError;
  final Duration delay;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  DebouncedLocationSearch(
      {required this.fetch,
      required this.onResult,
      this.onError,
      this.delay = const Duration(milliseconds: 350)});

  void update(String query) {
    if (_disposed) return;
    cancel();
    final generation = _generation;
    onResult(null);
    if (query.trim().length < 3) return;
    _timer = Timer(delay, () async {
      try {
        final result = await fetch(query.trim());
        if (!_disposed && generation == _generation) onResult(result);
      } catch (error) {
        if (!_disposed && generation == _generation) onError?.call(error);
      }
    });
  }

  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    cancel();
  }
}
