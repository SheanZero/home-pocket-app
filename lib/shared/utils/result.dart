/// Result wrapper for use case responses
///
/// Represents either a successful result with data or an error with message.
class Result<T> {
  final T? data;
  final String? error;

  const Result.success(this.data) : error = null;
  const Result.error(this.error) : data = null;

  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    } else {
      return 'Result.error($error)';
    }
  }
}
