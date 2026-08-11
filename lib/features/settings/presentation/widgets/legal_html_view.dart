import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Renders the small, trusted HTML subset used by bundled legal documents.
///
/// Keeping the renderer local avoids a WebView and ensures policies remain
/// available offline. Unsupported or executable elements are ignored.
class LegalHtmlView extends StatefulWidget {
  const LegalHtmlView({super.key, required this.html, this.uriLauncher});

  final String html;
  final Future<bool> Function(Uri uri)? uriLauncher;

  @override
  State<LegalHtmlView> createState() => _LegalHtmlViewState();
}

class _LegalHtmlViewState extends State<LegalHtmlView> {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final Map<String, TapGestureRecognizer> _linkRecognizers = {};

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fragment = html_parser.parseFragment(widget.html);
    final blocks = <Widget>[];

    for (final node in fragment.nodes) {
      blocks.addAll(_buildBlocks(node, palette));
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: blocks,
      ),
    );
  }

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Iterable<Widget> _buildBlocks(dom.Node node, AppPalette palette) sync* {
    if (node is dom.Text) {
      final text = node.data.trim();
      if (text.isNotEmpty) {
        yield _paragraph([dom.Text(text)], palette);
      }
      return;
    }
    if (node is! dom.Element) return;

    switch (node.localName) {
      case 'h1':
        yield Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _richText(
            node.nodes,
            AppTextStyles.pageTitle.copyWith(color: palette.textPrimary),
            palette,
            key: const Key('legal-html-h1'),
          ),
        );
      case 'h2':
        yield Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: _richText(
            node.nodes,
            AppTextStyles.sectionTitle.copyWith(color: palette.textPrimary),
            palette,
          ),
        );
      case 'h3':
        yield Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: _richText(
            node.nodes,
            AppTextStyles.itemTitle.copyWith(color: palette.textPrimary),
            palette,
          ),
        );
      case 'p':
        yield _paragraph(node.nodes, palette);
      case 'ul':
        yield _list(node, palette, ordered: false);
      case 'ol':
        yield _list(node, palette, ordered: true);
      case 'blockquote':
        yield Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: palette.backgroundMuted,
            border: Border(left: BorderSide(color: palette.accentPrimary)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: node.nodes
                .expand((child) => _buildBlocks(child, palette))
                .toList(growable: false),
          ),
        );
      case 'hr':
        yield Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: palette.borderDivider),
        );
      case 'script':
      case 'style':
      case 'head':
      case 'meta':
      case 'link':
        return;
      default:
        for (final child in node.nodes) {
          yield* _buildBlocks(child, palette);
        }
    }
  }

  Widget _paragraph(List<dom.Node> nodes, AppPalette palette) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _richText(
      nodes,
      AppTextStyles.body.copyWith(color: palette.textPrimary),
      palette,
    ),
  );

  Widget _list(dom.Element list, AppPalette palette, {required bool ordered}) {
    final items = list.children
        .where((element) => element.localName == 'li')
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      ordered ? '${index + 1}.' : '•',
                      style: AppTextStyles.body.copyWith(
                        color: palette.accentPrimaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _richText(
                      items[index].nodes,
                      AppTextStyles.body.copyWith(color: palette.textPrimary),
                      palette,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Text _richText(
    List<dom.Node> nodes,
    TextStyle style,
    AppPalette palette, {
    Key? key,
  }) => Text.rich(
    TextSpan(
      style: style,
      children: nodes
          .map((node) => _inlineSpan(node, palette))
          .toList(growable: false),
    ),
    key: key,
  );

  InlineSpan _inlineSpan(
    dom.Node node,
    AppPalette palette, {
    TapGestureRecognizer? inheritedRecognizer,
  }) {
    if (node is dom.Text) {
      return TextSpan(text: node.data, recognizer: inheritedRecognizer);
    }
    if (node is! dom.Element) return const TextSpan();

    if (node.localName == 'br') return const TextSpan(text: '\n');
    if ({'script', 'style', 'head', 'meta', 'link'}.contains(node.localName)) {
      return const TextSpan();
    }

    final linkUri = _supportedUri(node);
    final recognizer = linkUri == null
        ? inheritedRecognizer
        : _recognizerFor(linkUri);
    final elementStyle = switch (node.localName) {
      'strong' || 'b' => const TextStyle(fontWeight: FontWeight.w700),
      'em' || 'i' => const TextStyle(fontStyle: FontStyle.italic),
      'code' => TextStyle(
        fontFamily: 'monospace',
        color: palette.accentPrimaryText,
        backgroundColor: palette.backgroundMuted,
      ),
      _ => null,
    };
    final linkStyle = linkUri == null
        ? null
        : TextStyle(
            color: palette.accentPrimaryText,
            decoration: TextDecoration.underline,
            decorationColor: palette.accentPrimaryText,
          );

    return TextSpan(
      style: elementStyle?.merge(linkStyle) ?? linkStyle,
      children: node.nodes
          .map(
            (child) =>
                _inlineSpan(child, palette, inheritedRecognizer: recognizer),
          )
          .toList(growable: false),
    );
  }

  Uri? _supportedUri(dom.Element element) {
    final rawValue = switch (element.localName) {
      'a' => element.attributes['href']?.trim(),
      'code' => _uriValueForCode(element.text.trim()),
      _ => null,
    };
    if (rawValue == null || rawValue.isEmpty) return null;

    final uri = Uri.tryParse(rawValue);
    if (uri == null) return null;

    return switch (uri.scheme.toLowerCase()) {
      'http' || 'https' when uri.host.isNotEmpty => uri,
      'mailto' when _emailPattern.hasMatch(uri.path) => uri,
      _ => null,
    };
  }

  String? _uriValueForCode(String value) {
    if (_emailPattern.hasMatch(value)) return 'mailto:$value';

    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    return value;
  }

  TapGestureRecognizer _recognizerFor(Uri uri) {
    return _linkRecognizers.putIfAbsent(
      uri.toString(),
      () => TapGestureRecognizer()..onTap = () => unawaited(_openUri(uri)),
    );
  }

  Future<void> _openUri(Uri uri) async {
    try {
      final launcher = widget.uriLauncher ?? _launchExternal;
      await launcher(uri);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to open legal document link: ${error.runtimeType}');
      }
    }
  }

  Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
