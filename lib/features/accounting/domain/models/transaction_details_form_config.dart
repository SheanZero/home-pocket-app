import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';
import 'entry_source.dart';
import 'transaction.dart';

part 'transaction_details_form_config.freezed.dart';

/// Configures [TransactionDetailsForm] for either a new-entry or edit-existing flow.
///
/// Pattern-match via `config.when(...)` / `config.maybeWhen(...)` inside the form.
/// `.$new` carries optional initial values supplied by upstream entry screens;
/// `.edit` carries a fully-loaded [Transaction] seed whose immutable fields
/// (id, bookId, deviceId, prevHash, currentHash, createdAt, entrySource) are
/// preserved verbatim through the save (D-07/D-08).
///
/// Note: `$new` uses the `$` prefix because `new` is a Dart keyword.
/// Call site: `TransactionDetailsFormConfig.$new(...)`.
@freezed
sealed class TransactionDetailsFormConfig with _$TransactionDetailsFormConfig {
  const TransactionDetailsFormConfig._();

  /// New-entry mode. Initial field values are supplied by the caller;
  /// the widget never reaches into a repository to default values (D-06).
  const factory TransactionDetailsFormConfig.$new({
    required String bookId,
    int? initialAmount,
    Category? initialCategory,
    Category? initialParentCategory,
    String? initialMerchant,
    int? initialSatisfaction,
    DateTime? initialDate,
    required EntrySource entrySource,
    // Voice-correction keyword — present only in .new mode (D-09).
    String? voiceKeyword,
    // NOTE: Form-wiring (FocusNodes, picker-dismiss callback) is presentation
    // state and lives on the TransactionDetailsForm widget, NOT here — the
    // domain layer must stay free of package:flutter (CRIT-04 domain purity).
  }) = NewEntryConfig;

  /// Edit-existing mode. The full [Transaction] seed supplies all field values.
  /// [voiceKeyword] is structurally unreachable in this variant (D-09).
  const factory TransactionDetailsFormConfig.edit({required Transaction seed}) =
      EditEntryConfig;
}

/// Return type for [TransactionDetailsForm.submit()].
///
/// Pattern-match via `result.when(...)` in the host screen's save handler (D-02).
@freezed
sealed class TransactionDetailsFormResult with _$TransactionDetailsFormResult {
  const TransactionDetailsFormResult._();

  /// Save succeeded — [transaction] is the persisted/updated row.
  const factory TransactionDetailsFormResult.success(Transaction transaction) =
      _Success;

  /// Client-side validation failed — [message] is a user-facing error string.
  const factory TransactionDetailsFormResult.validationError(String message) =
      _ValidationError;

  /// Repository persist failed — [message] is a user-facing error string.
  const factory TransactionDetailsFormResult.persistError(String message) =
      _PersistError;
}
