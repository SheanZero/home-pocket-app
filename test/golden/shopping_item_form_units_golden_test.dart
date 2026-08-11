@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/load_numeral_font.dart';

class _MockCreate extends Mock implements CreateShoppingItemUseCase {}

class _MockUpdate extends Mock implements UpdateShoppingItemUseCase {}

class _FakeDeviceIdentityRepository implements DeviceIdentityRepository {
  @override
  Future<String?> getDeviceId() async => 'golden-device';
}

void main() {
  setUpAll(loadNumeralFont);

  testWidgets('shopping quantity and unit — light ja', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createShoppingItemUseCaseProvider.overrideWithValue(_MockCreate()),
          updateShoppingItemUseCaseProvider.overrideWithValue(_MockUpdate()),
          deviceIdentityRepositoryProvider.overrideWithValue(
            _FakeDeviceIdentityRepository(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ja'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: AppTheme.light,
          home: const ShoppingItemFormScreen(
            listType: 'public',
            unitSuggestions: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('shopping_form_name_field')),
      '砂糖',
    );
    await tester.enterText(
      find.byKey(const Key('shopping_form_quantity_field')),
      '200',
    );
    await tester.tap(find.byKey(const Key('shopping_form_unit_select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_unit_option_gram')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShoppingItemFormScreen),
      matchesGoldenFile('goldens/shopping_item_form_units_light_ja.png'),
    );

    await tester.tap(find.byKey(const Key('shopping_form_unit_select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopping_unit_option_custom')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('shopping_custom_unit_field')),
      'カップ',
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Overlay),
      matchesGoldenFile('goldens/shopping_unit_custom_sheet_light_ja.png'),
    );
  });
}
