import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/profile/presentation/screens/avatar_picker_screen.dart';
import 'package:home_pocket/shared/constants/warm_emojis.dart';

import '../../../helpers/test_localizations.dart';

void main() {
  testWidgets('show returns the selected avatar result', (tester) async {
    AvatarPickerResult? result;

    await tester.pumpWidget(
      createLocalizedWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AvatarPickerScreen.show(
                context,
                currentEmoji: warmEmojis.last,
              );
            },
            child: const Text('open'),
          ),
        ),
        locale: const Locale('ja'),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(warmEmojis.first));
    await tester.tap(find.textContaining('✓'));
    await tester.pumpAndSettle();

    expect(result?.emoji, warmEmojis.first);
    expect(result?.imagePath, isNull);
  });

  testWidgets('show returns null when the picker is cancelled', (tester) async {
    AvatarPickerResult? result;

    await tester.pumpWidget(
      createLocalizedWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AvatarPickerScreen.show(
                context,
                currentEmoji: warmEmojis.first,
              );
            },
            child: const Text('open'),
          ),
        ),
        locale: const Locale('ja'),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
