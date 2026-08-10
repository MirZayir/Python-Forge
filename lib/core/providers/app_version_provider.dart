import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current application version.
/// Implemented using a standard Provider to ensure immediate compilation
/// without requiring build_runner or code generation.
final appVersionProvider = Provider<String>((ref) {
  return '1.0.0';
});
