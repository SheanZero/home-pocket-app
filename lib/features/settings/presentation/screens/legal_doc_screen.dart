import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_locale.dart';

/// The legal documents this reader can render, each mapped to its bundled
/// asset stem (`assets/legal/{slug}_{lang}.md`).
enum LegalDoc {
  privacy,
  terms,
  tokusho;

  /// The asset filename stem for this document.
  String get slug => switch (this) {
        LegalDoc.privacy => 'privacy',
        LegalDoc.terms => 'terms',
        LegalDoc.tokusho => 'tokusho',
      };
}

/// Generic offline reader for the long-form legal drafts (privacy / terms /
/// 特商法) shipped as bundled per-locale Markdown assets (D-02, LEGAL-01/02/04).
///
/// This is the repo's first `rootBundle` consumer. The asset path is built from
/// two closed inputs only — the [LegalDoc] enum and a whitelist-guarded
/// language code — so no untrusted/system-supplied value can reach
/// [rootBundle.loadString] (V12 / T-56-02). The current UI language comes from
/// [currentLocaleProvider]; an unexpected locale falls back to `ja` and never
/// throws a missing-asset error.
///
/// Long legal text is rendered verbatim as plain [SelectableText] inside a
/// scroll view — no Markdown renderer dependency (RESEARCH A2). The AppBar title
/// is localized via [S]; theming follows [AppPaletteContext.palette] (ADR-019).
class LegalDocScreen extends ConsumerStatefulWidget {
  const LegalDocScreen({super.key, required this.doc});

  /// The legal document to display.
  final LegalDoc doc;

  @override
  ConsumerState<LegalDocScreen> createState() => _LegalDocScreenState();
}

class _LegalDocScreenState extends ConsumerState<LegalDocScreen> {
  /// Language codes with a guaranteed asset variant (56-01 parity gate).
  static const Set<String> _supportedLangs = {'ja', 'zh', 'en'};

  /// The asset path the current [_content] future was created for.
  String? _assetPath;

  /// Memoized load future — recreated ONLY when [_assetPath] changes (locale
  /// switch). Unrelated rebuilds (theme/palette, MediaQuery) reuse the same
  /// future so the FutureBuilder never resets to `waiting` and flashes the
  /// spinner over already-rendered legal text (WR-01).
  Future<String>? _content;

  String _titleFor(S l10n) => switch (widget.doc) {
        LegalDoc.privacy => l10n.privacyPolicy,
        LegalDoc.terms => l10n.termsOfUse,
        LegalDoc.tokusho => l10n.tokushoNotice,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    // V12 guard: whitelist the locale segment before it reaches the asset path.
    final lang = ref.watch(currentLocaleProvider).value?.languageCode ?? 'ja';
    final safeLang = _supportedLangs.contains(lang) ? lang : 'ja';
    final assetPath = 'assets/legal/${widget.doc.slug}_$safeLang.md';

    // Memoize: only rebuild the future when the resolved asset path changes.
    if (assetPath != _assetPath) {
      _assetPath = assetPath;
      _content = rootBundle.loadString(assetPath);
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(_titleFor(l10n))),
      body: FutureBuilder<String>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text(l10n.error));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(snapshot.data!),
          );
        },
      ),
    );
  }
}
