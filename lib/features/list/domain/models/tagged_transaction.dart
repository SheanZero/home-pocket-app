import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../accounting/domain/models/transaction.dart';

part 'tagged_transaction.freezed.dart';

/// Identifies a family member to whom a transaction is attributed.
///
/// Used in Phase 29 family multi-book mode to label transactions from shadow
/// books. In Phase 26 (own-book only), [TaggedTransaction.memberTag] is always
/// null; this VO is built fully now (D-07) so no type changes are needed in
/// Phase 29.
@freezed
abstract class MemberTag with _$MemberTag {
  const factory MemberTag({
    required String emoji,
    required String name,
  }) = _MemberTag;
}

/// A transaction enriched with optional family-member attribution.
///
/// This is the sealed contract between [listTransactionsProvider] and the list
/// UI. [memberTag] is null for own-book transactions (all of Phase 26);
/// Phase 29 fills it for shadow-book entries.
///
/// Freezed provides structural equality: two [TaggedTransaction]s are equal
/// when both [transaction] and [memberTag] are equal.
@freezed
abstract class TaggedTransaction with _$TaggedTransaction {
  const factory TaggedTransaction({
    required Transaction transaction,
    MemberTag? memberTag,
  }) = _TaggedTransaction;
}
