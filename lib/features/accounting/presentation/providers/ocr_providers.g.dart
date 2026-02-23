// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ocrServiceHash() => r'342d37395db413718a93888d7f344dd90f0df7ab';

/// OCRService — keepAlive because TextRecognizer is expensive to create.
/// Disposed when the app shuts down.
///
/// Copied from [ocrService].
@ProviderFor(ocrService)
final ocrServiceProvider = Provider<OCRService>.internal(
  ocrService,
  name: r'ocrServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ocrServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OcrServiceRef = ProviderRef<OCRService>;
String _$imagePreprocessorHash() => r'fb5b3ee378dc5ba2ec0ebbbf2855028cc6c0e564';

/// ImagePreprocessor — stateless, auto-disposed when not in use.
///
/// Copied from [imagePreprocessor].
@ProviderFor(imagePreprocessor)
final imagePreprocessorProvider =
    AutoDisposeProvider<ImagePreprocessor>.internal(
      imagePreprocessor,
      name: r'imagePreprocessorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$imagePreprocessorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImagePreprocessorRef = AutoDisposeProviderRef<ImagePreprocessor>;
String _$scanReceiptUseCaseHash() =>
    r'3635b3495d61acc3a98cd0befc6b65b65a405fac';

/// ScanReceiptUseCase — wired to OCR service and preprocessor.
///
/// Copied from [scanReceiptUseCase].
@ProviderFor(scanReceiptUseCase)
final scanReceiptUseCaseProvider =
    AutoDisposeProvider<ScanReceiptUseCase>.internal(
      scanReceiptUseCase,
      name: r'scanReceiptUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$scanReceiptUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanReceiptUseCaseRef = AutoDisposeProviderRef<ScanReceiptUseCase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
