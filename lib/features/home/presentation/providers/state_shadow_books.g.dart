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
    required ({DateTime startDate, DateTime endDate}) super.argument,
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
    final argument = this.argument as ({DateTime startDate, DateTime endDate});
    return shadowAggregate(
      ref,
      startDate: argument.startDate,
      endDate: argument.endDate,
    );
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

String _$shadowAggregateHash() => r'7ab7c002d00244c69d8938c10e5a83b527df4982';

final class ShadowAggregateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ShadowAggregate>,
          ({DateTime startDate, DateTime endDate})
        > {
  ShadowAggregateFamily._()
    : super(
        retry: null,
        name: r'shadowAggregateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShadowAggregateProvider call({
    required DateTime startDate,
    required DateTime endDate,
  }) => ShadowAggregateProvider._(
    argument: (startDate: startDate, endDate: endDate),
    from: this,
  );

  @override
  String toString() => r'shadowAggregateProvider';
}
