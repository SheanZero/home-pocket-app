import 'package:flutter/material.dart';

import '../../../../core/constants/feature_flags.dart';
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

  // 260614-iww: OCR entry is hidden behind kOcrEntryEnabled. The route config
  // map is kept intact (so the OcrScannerScreen import stays referenced and a
  // flag flip needs no re-add), but navigation to it is short-circuited while
  // the flag is false.
  if (toMode == InputMode.ocr && !kOcrEntryEnabled) return;

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
