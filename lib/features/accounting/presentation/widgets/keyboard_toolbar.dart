import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Shared TapRegion groupId so the KeyboardToolbar is treated as "inside"
/// by the merchant/note TextFields' onTapOutside handler. Without this, the
/// TextField's onTapOutside fires first on toolbar taps, unfocuses the field,
/// unmounts the toolbar before the InkWell's onTap resolves, and the save
/// never fires. See task 260526-r8y Item 3 root cause.
const String kKeyboardToolbarTapRegionGroup = 'manual-entry-keyboard-toolbar';

/// Floating keyboard accessory toolbar shown when a text field is focused.
///
/// Mounted inside ManualOneStepScreen via `Stack + Positioned(bottom:
/// MediaQuery.viewInsets.bottom)` — rides on top of the soft keyboard.
/// Left button: "Done" — dismisses soft keyboard (restores SmartKeyboard).
/// Right button: "Record" gradient — calls [onSave] (same handler as
/// SmartKeyboard's action-row Save key). See D-11/D-12/D-13.
///
/// `isSubmitting` is `true` both while a save is in flight AND while
/// `_selectedCategory == null` (P19-W1 dual-purpose disable). Callers pass
/// `isSubmitting: _isSubmitting || !_canSave`.
class KeyboardToolbar extends StatelessWidget {
  const KeyboardToolbar({
    super.key,
    required this.onDone,
    required this.onSave,
    required this.isSubmitting,
  });

  final VoidCallback onDone;
  final VoidCallback onSave;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TapRegion(
      groupId: kKeyboardToolbarTapRegionGroup,
      child: Material(
        color: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColorsDark.borderDefault
                    : AppColors.borderDefault,
              ),
            ),
          ),
          child: Row(
            children: [
              // Left: Done outlined ghost button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.card : AppColors.card,
                      border: Border.all(
                        color: isDark
                            ? AppColorsDark.borderDefault
                            : AppColors.borderDefault,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDone,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Text(
                            S.of(context).keyboardToolbarDone,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColorsDark.textPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Right: Save/Record gradient button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.actionGradientStart,
                          AppColors.actionGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isSubmitting ? null : onSave,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  S.of(context).record,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
