/// Simple Result type for use case return values.
///
/// Wraps either a success [data] value or an [error] message.
/// Used by application-layer use cases to communicate outcomes
/// without throwing exceptions.
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T? data) => Result._(data: data, isSuccess: true);

  factory Result.error(String message) =>
      Result._(error: message, isSuccess: false);

  bool get isError => !isSuccess;
}
