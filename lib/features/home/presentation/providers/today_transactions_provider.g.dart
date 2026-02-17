// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayTransactionsHash() => r'f91eeaaa4ab9c55f0b276f39c499c06f490bb3bd';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.
///
/// Copied from [todayTransactions].
@ProviderFor(todayTransactions)
const todayTransactionsProvider = TodayTransactionsFamily();

/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.
///
/// Copied from [todayTransactions].
class TodayTransactionsFamily extends Family<AsyncValue<List<Transaction>>> {
  /// Fetches today's non-deleted transactions for the given [bookId].
  ///
  /// Uses [GetTransactionsUseCase] with date range for the current day
  /// (00:00:00 to 23:59:59) and filters out soft-deleted records.
  ///
  /// Copied from [todayTransactions].
  const TodayTransactionsFamily();

  /// Fetches today's non-deleted transactions for the given [bookId].
  ///
  /// Uses [GetTransactionsUseCase] with date range for the current day
  /// (00:00:00 to 23:59:59) and filters out soft-deleted records.
  ///
  /// Copied from [todayTransactions].
  TodayTransactionsProvider call({required String bookId}) {
    return TodayTransactionsProvider(bookId: bookId);
  }

  @override
  TodayTransactionsProvider getProviderOverride(
    covariant TodayTransactionsProvider provider,
  ) {
    return call(bookId: provider.bookId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'todayTransactionsProvider';
}

/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.
///
/// Copied from [todayTransactions].
class TodayTransactionsProvider
    extends AutoDisposeFutureProvider<List<Transaction>> {
  /// Fetches today's non-deleted transactions for the given [bookId].
  ///
  /// Uses [GetTransactionsUseCase] with date range for the current day
  /// (00:00:00 to 23:59:59) and filters out soft-deleted records.
  ///
  /// Copied from [todayTransactions].
  TodayTransactionsProvider({required String bookId})
    : this._internal(
        (ref) => todayTransactions(ref as TodayTransactionsRef, bookId: bookId),
        from: todayTransactionsProvider,
        name: r'todayTransactionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$todayTransactionsHash,
        dependencies: TodayTransactionsFamily._dependencies,
        allTransitiveDependencies:
            TodayTransactionsFamily._allTransitiveDependencies,
        bookId: bookId,
      );

  TodayTransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
  }) : super.internal();

  final String bookId;

  @override
  Override overrideWith(
    FutureOr<List<Transaction>> Function(TodayTransactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayTransactionsProvider._internal(
        (ref) => create(ref as TodayTransactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Transaction>> createElement() {
    return _TodayTransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayTransactionsProvider && other.bookId == bookId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TodayTransactionsRef on AutoDisposeFutureProviderRef<List<Transaction>> {
  /// The parameter `bookId` of this provider.
  String get bookId;
}

class _TodayTransactionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Transaction>>
    with TodayTransactionsRef {
  _TodayTransactionsProviderElement(super.provider);

  @override
  String get bookId => (origin as TodayTransactionsProvider).bookId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
