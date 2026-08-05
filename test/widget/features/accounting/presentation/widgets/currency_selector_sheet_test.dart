import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/currency_selector_sheet.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  testWidgets('selecting a currency forwards its ISO code to the owner', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locale_providers.currentLocaleProvider.overrideWith(
            (_) async => const Locale('ja'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: CurrencySelectorSheet(onSelect: (code) => selected = code),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('currency-row-USD')));
    await tester.pumpAndSettle();

    expect(selected, 'USD');
  });
}
