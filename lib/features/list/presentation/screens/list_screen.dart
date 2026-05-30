import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../widgets/list_calendar_header.dart';

/// List screen for Phase 27 — mounts CalendarHeaderWidget at top.
///
/// Phase 28 will replace the placeholder spinner with a transaction list.
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod 3: .value is the nullable accessor (not .valueOrNull, which was removed)
    final locale =
        ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    // Phase 29: resolve currencyCode from bookByIdProvider
    const currencyCode = 'JPY';

    return Column(
      children: [
        CalendarHeaderWidget(
          bookId: bookId,
          currencyCode: currencyCode,
          locale: locale,
        ),
        // Phase 28: replace with transaction list
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}
