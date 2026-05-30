// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// GetListTransactionsUseCase provider.
///
/// Wires the list use case to the single [transactionRepositoryProvider]
/// from the accounting feature — no duplicate repository provider (T-26-02-DP
/// mitigated by importing with a `show` clause).

@ProviderFor(getListTransactionsUseCase)
final getListTransactionsUseCaseProvider =
    GetListTransactionsUseCaseProvider._();

/// GetListTransactionsUseCase provider.
///
/// Wires the list use case to the single [transactionRepositoryProvider]
/// from the accounting feature — no duplicate repository provider (T-26-02-DP
/// mitigated by importing with a `show` clause).

final class GetListTransactionsUseCaseProvider
    extends
        $FunctionalProvider<
          GetListTransactionsUseCase,
          GetListTransactionsUseCase,
          GetListTransactionsUseCase
        >
    with $Provider<GetListTransactionsUseCase> {
  /// GetListTransactionsUseCase provider.
  ///
  /// Wires the list use case to the single [transactionRepositoryProvider]
  /// from the accounting feature — no duplicate repository provider (T-26-02-DP
  /// mitigated by importing with a `show` clause).
  GetListTransactionsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getListTransactionsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getListTransactionsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetListTransactionsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetListTransactionsUseCase create(Ref ref) {
    return getListTransactionsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetListTransactionsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetListTransactionsUseCase>(value),
    );
  }
}

String _$getListTransactionsUseCaseHash() =>
    r'466fec96f1722d99af866b25b798a61a69ce692e';
