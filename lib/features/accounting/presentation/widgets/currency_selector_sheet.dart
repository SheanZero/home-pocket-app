import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../providers/state_recent_currency.dart';

/// One presentable currency row: ISO code + flag + display name.
///
/// The name is resolved from ARB for the common zone (via [localizedName]) and
/// falls back to the bundled English [englishName] for the long-tail "more"
/// list (RESEARCH Q1/Q2 — only the common zone is localized).
class _CurrencyEntry {
  const _CurrencyEntry({
    required this.code,
    required this.flag,
    required this.englishName,
  });

  final String code;
  final String flag;
  final String englishName;
}

/// Region-indicator flag emoji + region fallback (D-01). No-1:1-country
/// currencies (EUR) use a representative/neutral flag.
const Map<String, String> _flagByCode = <String, String>{
  'JPY': '🇯🇵',
  'USD': '🇺🇸',
  'EUR': '🇪🇺',
  'CNY': '🇨🇳',
  'HKD': '🇭🇰',
  'GBP': '🇬🇧',
  'KRW': '🇰🇷',
  'TWD': '🇹🇼',
  'SGD': '🇸🇬',
  'AUD': '🇦🇺',
  'CAD': '🇨🇦',
  'CHF': '🇨🇭',
  'THB': '🇹🇭',
  'INR': '🇮🇳',
  'IDR': '🇮🇩',
  'MYR': '🇲🇾',
  'PHP': '🇵🇭',
  'VND': '🇻🇳',
  'NZD': '🇳🇿',
  'BRL': '🇧🇷',
  'RUB': '🇷🇺',
  'ZAR': '🇿🇦',
  'SEK': '🇸🇪',
  'NOK': '🇳🇴',
  'DKK': '🇩🇰',
  'MXN': '🇲🇽',
  'TRY': '🇹🇷',
  'AED': '🇦🇪',
  'SAR': '🇸🇦',
  'PLN': '🇵🇱',
};

const String _fallbackFlag = '🏳️';

/// Long-tail ISO 4217 entries (English-only names) shown under "more".
/// The common zone (JPY + USD/EUR/CNY/HKD/GBP/KRW/TWD/SGD/AUD/CAD) is localized
/// via ARB; everything here falls back to ISO code + English name (RESEARCH Q2).
const List<_CurrencyEntry> _fullIsoList = <_CurrencyEntry>[
  _CurrencyEntry(code: 'CHF', flag: '🇨🇭', englishName: 'Swiss Franc'),
  _CurrencyEntry(code: 'THB', flag: '🇹🇭', englishName: 'Thai Baht'),
  _CurrencyEntry(code: 'INR', flag: '🇮🇳', englishName: 'Indian Rupee'),
  _CurrencyEntry(code: 'IDR', flag: '🇮🇩', englishName: 'Indonesian Rupiah'),
  _CurrencyEntry(code: 'MYR', flag: '🇲🇾', englishName: 'Malaysian Ringgit'),
  _CurrencyEntry(code: 'PHP', flag: '🇵🇭', englishName: 'Philippine Peso'),
  _CurrencyEntry(code: 'VND', flag: '🇻🇳', englishName: 'Vietnamese Dong'),
  _CurrencyEntry(code: 'NZD', flag: '🇳🇿', englishName: 'New Zealand Dollar'),
  _CurrencyEntry(code: 'BRL', flag: '🇧🇷', englishName: 'Brazilian Real'),
  _CurrencyEntry(code: 'RUB', flag: '🇷🇺', englishName: 'Russian Ruble'),
  _CurrencyEntry(code: 'ZAR', flag: '🇿🇦', englishName: 'South African Rand'),
  _CurrencyEntry(code: 'SEK', flag: '🇸🇪', englishName: 'Swedish Krona'),
  _CurrencyEntry(code: 'NOK', flag: '🇳🇴', englishName: 'Norwegian Krone'),
  _CurrencyEntry(code: 'DKK', flag: '🇩🇰', englishName: 'Danish Krone'),
  _CurrencyEntry(code: 'MXN', flag: '🇲🇽', englishName: 'Mexican Peso'),
  _CurrencyEntry(code: 'TRY', flag: '🇹🇷', englishName: 'Turkish Lira'),
  _CurrencyEntry(code: 'AED', flag: '🇦🇪', englishName: 'UAE Dirham'),
  _CurrencyEntry(code: 'SAR', flag: '🇸🇦', englishName: 'Saudi Riyal'),
  _CurrencyEntry(code: 'PLN', flag: '🇵🇱', englishName: 'Polish Zloty'),
];

/// Resolve the localized display name for a common-zone [code] via ARB.
/// Returns null for codes outside the localized common zone (long-tail).
String? _localizedCommonZoneName(S s, String code) {
  switch (code) {
    case 'JPY':
      return s.currencyNameJpy;
    case 'USD':
      return s.currencyNameUsd;
    case 'EUR':
      return s.currencyNameEur;
    case 'CNY':
      return s.currencyNameCny;
    case 'HKD':
      return s.currencyNameHkd;
    case 'GBP':
      return s.currencyNameGbp;
    case 'KRW':
      return s.currencyNameKrw;
    case 'TWD':
      return s.currencyNameTwd;
    case 'SGD':
      return s.currencyNameSgd;
    case 'AUD':
      return s.currencyNameAud;
    case 'CAD':
      return s.currencyNameCad;
    default:
      return null;
  }
}

/// Currency selection bottom sheet (CURR-01/02/03, D-01/D-02).
///
/// Default view: JPY pinned first, then the common zone (USD/EUR/CNY/HKD/GBP)
/// re-ordered by recent use (`recentCurrencyProvider`). A "more" affordance
/// (D-02) expands the source to the full ISO 4217 list. A search field filters
/// rows by ISO code OR name (CURR-02). Selecting a row calls [onSelect] with the
/// ISO code, records recent use, and pops (CURR-03) — selection never leaves the
/// entry screen.
///
/// Row format = flag emoji + currency symbol + ISO code + localized name
/// (`🇺🇸 $ USD 米ドル`, D-01). [showFlags] is false in golden mode so the
/// host-font-dependent flag glyph does not couple to the baseline (RESEARCH Q2).
class CurrencySelectorSheet extends ConsumerStatefulWidget {
  const CurrencySelectorSheet({
    super.key,
    required this.onSelect,
    this.selectedCode,
    this.showFlags = true,
  });

  /// Invoked with the chosen ISO 4217 code when a row is tapped.
  final ValueChanged<String> onSelect;

  /// Currently active currency (highlighted with the leaf-green accent).
  final String? selectedCode;

  /// When false, the flag cell is masked (rendered as a blank fixed-width box)
  /// so emoji-font pixels don't couple to golden baselines (RESEARCH Q2).
  final bool showFlags;

  @override
  ConsumerState<CurrencySelectorSheet> createState() =>
      _CurrencySelectorSheetState();
}

class _CurrencySelectorSheetState
    extends ConsumerState<CurrencySelectorSheet> {
  String _query = '';
  bool _showAll = false;

  /// Common-zone codes (JPY pinned first), then the rest re-ordered by recent
  /// use. Long-tail entries are appended only when "more" is expanded.
  List<_CurrencyEntry> _entries(S s) {
    final orderedCommon =
        ref.read(recentCurrencyProvider.notifier).orderedCommonZone();

    _CurrencyEntry entryFor(String code) => _CurrencyEntry(
          code: code,
          flag: _flagByCode[code] ?? _fallbackFlag,
          englishName: code,
        );

    final common = <_CurrencyEntry>[
      // JPY ALWAYS first; never participates in recent-use reordering.
      entryFor('JPY'),
      for (final code in orderedCommon) entryFor(code),
    ];

    if (!_showAll) return common;

    final commonCodes = common.map((e) => e.code).toSet();
    final longTail =
        _fullIsoList.where((e) => !commonCodes.contains(e.code)).toList();
    return <_CurrencyEntry>[...common, ...longTail];
  }

  bool _matches(S s, _CurrencyEntry entry) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final name =
        (_localizedCommonZoneName(s, entry.code) ?? entry.englishName)
            .toLowerCase();
    return entry.code.toLowerCase().contains(q) || name.contains(q);
  }

  void _select(String code) {
    ref.read(recentCurrencyProvider.notifier).recordUse(code);
    widget.onSelect(code);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    final palette = context.palette;
    final screenHeight = MediaQuery.of(context).size.height;

    final visible =
        _entries(s).where((e) => _matches(s, e)).toList(growable: false);

    return Container(
      height: screenHeight * 0.65,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.borderDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.currencySelectorTitle,
                  style: AppTextStyles.titleMedium,
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    s.listDeleteCancelButton,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              key: const ValueKey('currency-search-field'),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: s.currencySelectorSearchHint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: palette.textSecondary,
                ),
                filled: true,
                fillColor: palette.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.borderDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.borderDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.borderInputActive),
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: palette.borderDivider),
          // Currency rows
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      s.currencySelectorNoResults,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final entry = visible[index];
                      return _CurrencyRow(
                        entry: entry,
                        locale: locale,
                        localizedName: _localizedCommonZoneName(s, entry.code),
                        isSelected: entry.code == widget.selectedCode,
                        showFlag: widget.showFlags,
                        onTap: () => _select(entry.code),
                      );
                    },
                  ),
          ),
          // "More" affordance (D-02) — only when not already expanded.
          if (!_showAll)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: palette.borderDivider, width: 1),
                ),
              ),
              child: InkWell(
                key: const ValueKey('currency-more-button'),
                onTap: () => setState(() => _showAll = true),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Text(
                    s.currencySelectorMore,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: palette.accentPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single 48dp currency row: flag + symbol + ISO code + localized name (D-01).
class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.entry,
    required this.locale,
    required this.localizedName,
    required this.isSelected,
    required this.showFlag,
    required this.onTap,
  });

  final _CurrencyEntry entry;
  final Locale locale;
  final String? localizedName;
  final bool isSelected;
  final bool showFlag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = localizedName ?? entry.englishName;
    // Symbol from the shared NumberFormatter map (ISO-code fallback inside).
    final symbol = NumberFormatter.formatCurrency(0, entry.code, locale)
        .replaceAll(RegExp(r'[\d.,\s]'), '');

    return InkWell(
      key: ValueKey('currency-row-${entry.code}'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        color: isSelected ? palette.accentPrimaryLight : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Flag cell — fixed width; masked (blank) in golden mode so the
            // host-font-dependent emoji glyph does not couple to baselines.
            SizedBox(
              width: 28,
              child: showFlag
                  ? Text(entry.flag, style: const TextStyle(fontSize: 20))
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            // Symbol
            SizedBox(
              width: 40,
              child: Text(
                symbol,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // ISO code
            SizedBox(
              width: 44,
              child: Text(
                entry.code,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? palette.accentPrimary
                      : palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Localized name
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected
                      ? palette.accentPrimary
                      : palette.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 20, color: palette.accentPrimary),
          ],
        ),
      ),
    );
  }
}
