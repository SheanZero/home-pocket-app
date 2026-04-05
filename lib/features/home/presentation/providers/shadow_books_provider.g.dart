// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shadow_books_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shadowBooksHash() => r'9f2071d04cd0fdf0c5b587aa4bbcbda9f3231446';

/// See also [shadowBooks].
@ProviderFor(shadowBooks)
final shadowBooksProvider =
    AutoDisposeFutureProvider<List<ShadowBookInfo>>.internal(
      shadowBooks,
      name: r'shadowBooksProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shadowBooksHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShadowBooksRef = AutoDisposeFutureProviderRef<List<ShadowBookInfo>>;
String _$shadowAggregateHash() => r'e67d7c0c27079f961e5f001e1f93f8fbbc911e1d';

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

/// See also [shadowAggregate].
@ProviderFor(shadowAggregate)
const shadowAggregateProvider = ShadowAggregateFamily();

/// See also [shadowAggregate].
class ShadowAggregateFamily extends Family<AsyncValue<ShadowAggregate>> {
  /// See also [shadowAggregate].
  const ShadowAggregateFamily();

  /// See also [shadowAggregate].
  ShadowAggregateProvider call({required int year, required int month}) {
    return ShadowAggregateProvider(year: year, month: month);
  }

  @override
  ShadowAggregateProvider getProviderOverride(
    covariant ShadowAggregateProvider provider,
  ) {
    return call(year: provider.year, month: provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shadowAggregateProvider';
}

/// See also [shadowAggregate].
class ShadowAggregateProvider
    extends AutoDisposeFutureProvider<ShadowAggregate> {
  /// See also [shadowAggregate].
  ShadowAggregateProvider({required int year, required int month})
    : this._internal(
        (ref) => shadowAggregate(
          ref as ShadowAggregateRef,
          year: year,
          month: month,
        ),
        from: shadowAggregateProvider,
        name: r'shadowAggregateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shadowAggregateHash,
        dependencies: ShadowAggregateFamily._dependencies,
        allTransitiveDependencies:
            ShadowAggregateFamily._allTransitiveDependencies,
        year: year,
        month: month,
      );

  ShadowAggregateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<ShadowAggregate> Function(ShadowAggregateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShadowAggregateProvider._internal(
        (ref) => create(ref as ShadowAggregateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ShadowAggregate> createElement() {
    return _ShadowAggregateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShadowAggregateProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShadowAggregateRef on AutoDisposeFutureProviderRef<ShadowAggregate> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _ShadowAggregateProviderElement
    extends AutoDisposeFutureProviderElement<ShadowAggregate>
    with ShadowAggregateRef {
  _ShadowAggregateProviderElement(super.provider);

  @override
  int get year => (origin as ShadowAggregateProvider).year;
  @override
  int get month => (origin as ShadowAggregateProvider).month;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
