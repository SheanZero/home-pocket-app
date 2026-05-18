// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_shadow_books.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shadowBooks)
final shadowBooksProvider = ShadowBooksProvider._();

final class ShadowBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShadowBookInfo>>,
          List<ShadowBookInfo>,
          FutureOr<List<ShadowBookInfo>>
        >
    with
        $FutureModifier<List<ShadowBookInfo>>,
        $FutureProvider<List<ShadowBookInfo>> {
  ShadowBooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shadowBooksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shadowBooksHash();

  @$internal
  @override
  $FutureProviderElement<List<ShadowBookInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShadowBookInfo>> create(Ref ref) {
    return shadowBooks(ref);
  }
}

String _$shadowBooksHash() => r'3f7b8df77348d3a2c3b3347f963beef28c20f1a8';

@ProviderFor(shadowAggregate)
final shadowAggregateProvider = ShadowAggregateFamily._();

final class ShadowAggregateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShadowAggregate>,
          ShadowAggregate,
          FutureOr<ShadowAggregate>
        >
    with $FutureModifier<ShadowAggregate>, $FutureProvider<ShadowAggregate> {
  ShadowAggregateProvider._({
    required ShadowAggregateFamily super.from,
    required ({int year, int month}) super.argument,
  }) : super(
         retry: null,
         name: r'shadowAggregateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shadowAggregateHash();

  @override
  String toString() {
    return r'shadowAggregateProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ShadowAggregate> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShadowAggregate> create(Ref ref) {
    final argument = this.argument as ({int year, int month});
    return shadowAggregate(ref, year: argument.year, month: argument.month);
  }

  @override
  bool operator ==(Object other) {
    return other is ShadowAggregateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shadowAggregateHash() => r'e67d7c0c27079f961e5f001e1f93f8fbbc911e1d';

final class ShadowAggregateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ShadowAggregate>,
          ({int year, int month})
        > {
  ShadowAggregateFamily._()
    : super(
        retry: null,
        name: r'shadowAggregateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShadowAggregateProvider call({required int year, required int month}) =>
      ShadowAggregateProvider._(
        argument: (year: year, month: month),
        from: this,
      );

  @override
  String toString() => r'shadowAggregateProvider';
}
