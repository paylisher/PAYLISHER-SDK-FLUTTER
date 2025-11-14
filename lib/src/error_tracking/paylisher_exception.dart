import 'package:meta/meta.dart';

/// A wrapper exception that carries Paylisher-specific metadata
@internal
class PaylisherException implements Exception {
  /// The original exception/error that was wrapped
  final Object source;
  final String mechanism;
  final bool handled;

  const PaylisherException({
    required this.source,
    required this.mechanism,
    this.handled = false,
  });
}
