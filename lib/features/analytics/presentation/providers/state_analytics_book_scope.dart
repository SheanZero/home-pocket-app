import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';

/// Resolves the ledger scope used by Statistics.
///
/// A local member's transactions live in [primaryBookId], while synchronized
/// transactions from the other active-family members live in shadow books.
/// Statistics must query the union. Outside group mode the primary book remains
/// the complete scope.
Future<List<String>> resolveAnalyticsBookIds(
  Ref ref, {
  required String primaryBookId,
  bool includeFamily = true,
}) async {
  if (!includeFamily || !ref.watch(isGroupModeProvider)) {
    return [primaryBookId];
  }

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  return <String>{
    primaryBookId,
    ...shadowBooks.map((shadow) => shadow.book.id),
  }.toList(growable: false);
}
