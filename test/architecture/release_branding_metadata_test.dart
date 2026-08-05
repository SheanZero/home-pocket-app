import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _brandName = 'Happy Pocket';
const _websiteUrl = 'https://happypocket.app/';

void main() {
  group('release branding metadata contract', () {
    test('the in-app brand is consistent across supported locales', () {
      for (final locale in const ['en', 'ja', 'zh']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>;

        expect(arb['appName'], _brandName, reason: 'app_$locale.arb');
      }
    });

    test('Android launcher label uses the branded string resource', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:label="@string/app_name"'));
      for (final path in const [
        'android/app/src/main/res/values/strings.xml',
        'android/app/src/main/res/values-ja/strings.xml',
        'android/app/src/main/res/values-zh/strings.xml',
      ]) {
        expect(File(path).readAsStringSync(), contains('>$_brandName<'));
      }
    });

    test('storefront names and subtitles match the approved localization', () {
      const expected = <String, (String, String)>{
        'en-US': (
          'Happy Pocket: Family Budget',
          'Private budgeting for families',
        ),
        'ja': ('ハピポケ家族家計簿', '家族で共有できる安心の家計簿'),
        'zh-Hans': ('Happy Pocket 家庭账本', '本地优先的家庭共享记账本'),
      };

      for (final entry in expected.entries) {
        final directory = 'publish/ios/metadata/${entry.key}';
        expect(
          File('$directory/name.txt').readAsStringSync().trim(),
          entry.value.$1,
        );
        expect(
          File('$directory/subtitle.txt').readAsStringSync().trim(),
          entry.value.$2,
        );
        for (final fileName in const [
          'marketing_url.txt',
          'privacy_url.txt',
          'support_url.txt',
        ]) {
          expect(
            File('$directory/$fileName').readAsStringSync().trim(),
            startsWith(_websiteUrl),
            reason: '$directory/$fileName',
          );
        }
      }
    });

    test(
      'the official website uses the production domain and three locales',
      () {
        final config = File('website/hugo.toml').readAsStringSync();

        expect(config, contains('baseURL = "$_websiteUrl"'));
        expect(config, contains('[languages.en]'));
        expect(config, contains('[languages.ja]'));
        expect(config, contains('[languages.zh]'));
        expect(Directory('website/content/zh').existsSync(), isTrue);
        expect(File('website/i18n/zh.yaml').existsSync(), isTrue);
      },
    );

    test('release surfaces do not retain retired public names', () {
      const retiredNames = ['Home Pocket', 'まもる家計簿', '守护家计簿', '家庭口袋'];
      const roots = [
        'assets/legal',
        'publish/ios',
        'website/content',
        'website/i18n',
      ];

      for (final root in roots) {
        for (final entity in Directory(root).listSync(recursive: true)) {
          if (entity is! File || _isBinary(entity.path)) continue;
          final contents = entity.readAsStringSync();
          for (final retiredName in retiredNames) {
            expect(
              contents,
              isNot(contains(retiredName)),
              reason: '${entity.path} still contains $retiredName',
            );
          }
        }
      }
    });

    test('App Review contact uses the approved operator details', () {
      const name = '張欣';
      const company = 'ナープ株式会社';
      const email = 'support@napu.co.jp';
      const phone = '03-6859-7235';
      final reviewNotes = File(
        'publish/ios/review/app_review_notes_en.txt',
      ).readAsStringSync();
      final requiredValues = File(
        'publish/ios/REQUIRED_VALUES.env.example',
      ).readAsStringSync();

      for (final value in [name, company, email, phone]) {
        expect(reviewNotes, contains(value));
      }
      expect(reviewNotes, isNot(contains('__REQUIRED_REVIEW_CONTACT_')));
      expect(requiredValues, contains('REVIEW_FIRST_NAME="欣"'));
      expect(requiredValues, contains('REVIEW_LAST_NAME="張"'));
      expect(requiredValues, contains('REVIEW_COMPANY="$company"'));
      expect(requiredValues, contains('REVIEW_EMAIL="$email"'));
      expect(requiredValues, contains('REVIEW_PHONE="$phone"'));
      expect(requiredValues, isNot(contains('__REQUIRED_REVIEW_CONTACT_')));
    });
  });
}

bool _isBinary(String path) {
  const textExtensions = {
    '.md',
    '.txt',
    '.yaml',
    '.yml',
    '.toml',
    '.html',
    '.json',
    '.svg',
  };
  return !textExtensions.any(path.endsWith);
}
