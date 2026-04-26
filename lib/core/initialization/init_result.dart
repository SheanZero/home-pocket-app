import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'init_result.freezed.dart';

enum InitFailureType { masterKey, database, seed, unknown }

@freezed
sealed class InitResult with _$InitResult {
  const factory InitResult.success({
    required ProviderContainer container,
  }) = InitSuccess;

  const factory InitResult.failure({
    required InitFailureType type,
    required Object error,
    StackTrace? stackTrace,
  }) = InitFailure;
}
