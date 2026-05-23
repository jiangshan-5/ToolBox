import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global cross-tool clipboard provider.
///
/// Any tool can write a text payload here; any other tool can read it
/// as a pre-filled input. This enables zero-friction data flow between
/// tools (e.g. Word Counter → AI Processor, AI → Markdown Editor).
final globalClipboardProvider = StateProvider<String?>((ref) => null);
