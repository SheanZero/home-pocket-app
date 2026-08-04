import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/repository_providers.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// The two-step values the set-PIN flow walks through (D-03).
enum _SetPinStep { enter, confirm }

/// Reusable double-entry set-PIN flow (sketch 004A — D-03 / LOCK-06).
///
/// Composes the Plan 08 presentational [PinKeypad] / [PinDots] and drives them
/// with a two-step state machine:
///
///   * **enter**: type a fresh 4-digit PIN ([S.appLockSetPinTitle]). On the 4th
///     digit the entry is captured and the screen advances to the confirm step
///     (no submit key — matching the D-12 instant input feel).
///   * **confirm**: re-enter the same 4 digits ([S.appLockConfirmPinTitle]). On
///     the 4th digit it compares: equal → `AppLockService.setPin(pin)` then
///     reports success; unequal → shows [S.appLockPinMismatch], shakes + clears
///     the dots, and restarts at the enter step. A typo can therefore never
///     persist a PIN the user does not know (T-55-26).
///
/// The half-entered first PIN lives only in widget state; nothing is written
/// until a successful confirm. Plaintext PINs are never logged. Theming is via
/// [AppPaletteContext.palette] (ADR-019 v1.6); strings via [S].
///
/// Success is reported via [onCompleted] when provided; otherwise the screen
/// pops itself with `true` so a `Navigator.push<bool>` caller (the Settings
/// master toggle / 修改 PIN entry) can react. Dismissing without finishing
/// (close button / system back) yields no result, so the caller leaves the lock
/// state untouched (never enable without a PIN).
class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key, this.isUpdating = false, this.onCompleted});

  /// Whether this flow replaces an existing PIN rather than creating one.
  /// The interaction remains identical; only the first-step heading changes.
  final bool isUpdating;

  /// Fired exactly once after the PIN is successfully set. When null the screen
  /// instead pops itself with `true`.
  final VoidCallback? onCompleted;

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  static const int _pinLength = 4;

  _SetPinStep _step = _SetPinStep.enter;
  String _entered = '';
  String _firstPin = '';
  int _errorTrigger = 0;
  bool _mismatch = false;
  bool _saving = false;

  void _onDigit(int digit) {
    if (_saving || _entered.length >= _pinLength) {
      return;
    }
    setState(() {
      _mismatch = false;
      _entered += '$digit';
    });
    if (_entered.length == _pinLength) {
      _onComplete();
    }
  }

  void _onBackspace() {
    if (_saving || _entered.isEmpty) {
      return;
    }
    setState(() {
      _mismatch = false;
      _entered = _entered.substring(0, _entered.length - 1);
    });
  }

  void _onComplete() {
    if (_step == _SetPinStep.enter) {
      setState(() {
        _firstPin = _entered;
        _entered = '';
        _step = _SetPinStep.confirm;
      });
      return;
    }
    if (_entered == _firstPin) {
      _persist(_entered);
    } else {
      // Mismatch: never persist; shake + clear and restart from the enter step.
      setState(() {
        _entered = '';
        _firstPin = '';
        _step = _SetPinStep.enter;
        _errorTrigger += 1;
        _mismatch = true;
      });
    }
  }

  Future<void> _persist(String pin) async {
    setState(() => _saving = true);
    await ref.read(appLockServiceProvider).setPin(pin);
    if (!mounted) {
      return;
    }
    if (widget.onCompleted != null) {
      widget.onCompleted!();
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = S.of(context);
    final title = _step == _SetPinStep.enter
        ? (widget.isUpdating ? l.appLockUpdatePinTitle : l.appLockSetPinTitle)
        : l.appLockConfirmPinTitle;
    final description = _step == _SetPinStep.enter
        ? l.appLockSetPinDescription
        : l.appLockConfirmPinDescription;
    final currentStep = _step == _SetPinStep.enter ? 1 : 2;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          key: const ValueKey('set-pin-close'),
          icon: Icon(Icons.close, color: palette.textSecondary),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 16,
              ),
              child: Center(
                child: SizedBox(
                  width: 318,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          key: const ValueKey('set-pin-visual'),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: palette.accentPrimaryLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: palette.accentPrimaryBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.password_rounded,
                            size: 29,
                            color: palette.dailyText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          description,
                          key: ValueKey(description),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PinStepProgress(
                        currentStep: currentStep,
                        semanticLabel: l.appLockPinSetupProgress(
                          currentStep,
                          2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: PinDots(
                          filledCount: _entered.length,
                          length: _pinLength,
                          errorTrigger: _errorTrigger,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 18,
                        child: _mismatch
                            ? Text(
                                l.appLockPinMismatch,
                                key: const ValueKey('set-pin-mismatch'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.error,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinStepProgress extends StatelessWidget {
  const _PinStepProgress({
    required this.currentStep,
    required this.semanticLabel,
  });

  final int currentStep;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        key: const ValueKey('set-pin-progress'),
        children: [
          Expanded(
            child: Row(
              children: [
                for (var step = 1; step <= 2; step++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 4,
                      decoration: BoxDecoration(
                        color: step <= currentStep
                            ? palette.accentPrimary
                            : palette.borderDefault,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  if (step == 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currentStep / 2',
            key: ValueKey('set-pin-step-$currentStep'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
