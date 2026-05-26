import 'package:flutter/material.dart';

import '../screens/ocr_scanner_screen.dart';
import '../screens/manual_one_step_screen.dart';
import '../screens/voice_input_screen.dart';
import '../widgets/input_mode_tabs.dart';

/// Unified route config for add-transaction input modes.
class EntryModeRouteConfig {
  const EntryModeRouteConfig({
    required this.mode,
    required this.builder,
    this.replaceCurrent = true,
  });

  final InputMode mode;
  final Widget Function(String bookId) builder;
  final bool replaceCurrent;
}

final _entryModeRouteConfigs = <InputMode, EntryModeRouteConfig>{
  InputMode.manual: EntryModeRouteConfig(
    mode: InputMode.manual,
    builder: (bookId) => ManualOneStepScreen(bookId: bookId),
  ),
  InputMode.ocr: EntryModeRouteConfig(
    mode: InputMode.ocr,
    builder: (bookId) => OcrScannerScreen(bookId: bookId),
  ),
  InputMode.voice: EntryModeRouteConfig(
    mode: InputMode.voice,
    builder: (bookId) => VoiceInputScreen(bookId: bookId),
  ),
};

void navigateToEntryMode({
  required BuildContext context,
  required InputMode fromMode,
  required InputMode toMode,
  required String bookId,
}) {
  if (fromMode == toMode) return;

  final config = _entryModeRouteConfigs[toMode];
  if (config == null) return;

  final route = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => config.builder(bookId),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_, _, _, child) => child,
  );

  if (config.replaceCurrent) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}
