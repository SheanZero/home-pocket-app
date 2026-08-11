import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/features/settings/presentation/screens/legal_doc_screen.dart';
import 'package:home_pocket/features/settings/presentation/widgets/legal_html_view.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../helpers/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // rootBundle caches decoded strings; a cache-hit reload leaves the
  // FutureBuilder spinner animating the simulated clock, timing out
  // pumpAndSettle. Evict between tests so every load is a fresh (settling) miss.
  tearDown(rootBundle.clear);

  /// Pumps [LegalDocScreen] for [doc], overriding the current locale so the
  /// asset language segment is deterministic (independent of host prefs).
  Future<void> pump(
    WidgetTester tester, {
    required LegalDoc doc,
    required Locale locale,
  }) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        LegalDocScreen(doc: doc),
        locale: locale,
        overrides: [currentLocaleProvider.overrideWith((ref) async => locale)],
      ),
    );
    await tester.pumpAndSettle();
  }

  S l10nOf(WidgetTester tester) =>
      S.of(tester.element(find.byType(LegalDocScreen)));

  /// All visible HTML text rendered inside [LegalHtmlView].
  String bodyText(WidgetTester tester) {
    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(LegalHtmlView),
        matching: find.byType(Text),
      ),
    );
    return texts
        .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
        .join('\n');
  }

  Iterable<TextSpan> descendantTextSpans(InlineSpan span) sync* {
    if (span is! TextSpan) return;
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* descendantTextSpans(child);
    }
  }

  TextSpan spanWithText(WidgetTester tester, String text) {
    final richText = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains(text) == true,
      ),
    );
    return descendantTextSpans(
      richText.textSpan!,
    ).singleWhere((span) => span.text == text);
  }

  group('LegalDocScreen', () {
    testWidgets('HTML links and code-form URLs/emails open supported URIs', (
      tester,
    ) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        createLocalizedWidget(
          LegalHtmlView(
            html: '''
              <p><a href="https://happypocket.app/privacy">Website</a></p>
              <p><code>https://happypocket.app/terms</code></p>
              <p><code>support@napu.co.jp</code></p>
              <p><a href="javascript:alert(1)">Unsafe</a></p>
            ''',
            uriLauncher: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );

      for (final label in [
        'Website',
        'https://happypocket.app/terms',
        'support@napu.co.jp',
      ]) {
        final recognizer = spanWithText(tester, label).recognizer;
        expect(recognizer, isA<TapGestureRecognizer>());
        (recognizer! as TapGestureRecognizer).onTap!();
      }

      expect(spanWithText(tester, 'Unsafe').recognizer, isNull);
      expect(opened, [
        Uri.parse('https://happypocket.app/privacy'),
        Uri.parse('https://happypocket.app/terms'),
        Uri.parse('mailto:support@napu.co.jp'),
      ]);
    });

    testWidgets('privacy (ja) renders privacy_ja.html as styled HTML '
        '(LEGAL-01)', (tester) async {
      await pump(tester, doc: LegalDoc.privacy, locale: const Locale('ja'));

      expect(find.byType(LegalHtmlView), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      // Body-only marker present in the ja privacy asset.
      expect(bodyText(tester), contains('プライバシーポリシー'));
      expect(bodyText(tester), contains('Happy Pocket'));
      expect(bodyText(tester), isNot(contains('# ')));
      expect(bodyText(tester), isNot(contains('**')));

      final h1 = tester.widget<Text>(find.byKey(const Key('legal-html-h1')));
      expect(h1.textSpan?.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('terms (ja) renders terms content (LEGAL-02)', (tester) async {
      await pump(tester, doc: LegalDoc.terms, locale: const Locale('ja'));

      expect(find.byType(LegalHtmlView), findsOneWidget);
      expect(bodyText(tester), contains('利用規約'));
    });

    testWidgets('tokusho (ja) renders published operator fields '
        '(full 表記型 — LEGAL-04 / D-06 supersedes D-03)', (tester) async {
      await pump(tester, doc: LegalDoc.tokusho, locale: const Locale('ja'));

      expect(find.byType(LegalHtmlView), findsOneWidget);
      // Full 表記型 (D-06): the notice now publishes the operator fields
      // directly — 事業者名 / 所在地 / 電話番号 / 運営責任者. 運営責任者 is a
      // published-operator field that exists ONLY in the full-表記 rewrite.
      expect(bodyText(tester), contains('運営責任者'));
    });

    testWidgets('locale switch (zh) loads the _zh.html variant', (
      tester,
    ) async {
      await pump(tester, doc: LegalDoc.privacy, locale: const Locale('zh'));

      // zh-only heading, absent from the ja/en variants.
      expect(bodyText(tester), contains('隐私政策'));
    });

    testWidgets('unsupported locale falls back to ja and never throws '
        '(V12 whitelist guard)', (tester) async {
      await pump(tester, doc: LegalDoc.privacy, locale: const Locale('fr'));

      expect(tester.takeException(), isNull);
      // Fell back to the ja asset (whitelist default), not a missing-asset error.
      expect(bodyText(tester), contains('プライバシーポリシー'));
    });

    testWidgets('AppBar title comes from S per doc (privacyPolicy)', (
      tester,
    ) async {
      await pump(tester, doc: LegalDoc.privacy, locale: const Locale('ja'));

      final l10n = l10nOf(tester);
      expect(find.widgetWithText(AppBar, l10n.privacyPolicy), findsOneWidget);
    });

    testWidgets('AppBar title comes from S per doc (termsOfUse)', (
      tester,
    ) async {
      await pump(tester, doc: LegalDoc.terms, locale: const Locale('ja'));

      final l10n = l10nOf(tester);
      expect(find.widgetWithText(AppBar, l10n.termsOfUse), findsOneWidget);
    });

    testWidgets('AppBar title comes from S per doc (tokushoNotice)', (
      tester,
    ) async {
      await pump(tester, doc: LegalDoc.tokusho, locale: const Locale('ja'));

      final l10n = l10nOf(tester);
      expect(find.widgetWithText(AppBar, l10n.tokushoNotice), findsOneWidget);
    });

    test('LegalDoc.slug maps each doc to its asset stem', () {
      expect(LegalDoc.privacy.slug, 'privacy');
      expect(LegalDoc.terms.slug, 'terms');
      expect(LegalDoc.tokusho.slug, 'tokusho');
    });
  });
}
