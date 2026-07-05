/// Runs a multi-repository write sequence atomically.
///
/// The data-layer implementation wraps [run] in a single database
/// transaction: if the action throws, every repository write made inside it
/// is rolled back. Non-database side effects (e.g. SharedPreferences) are
/// NOT rolled back — order them last inside the action.
abstract class UnitOfWork {
  Future<T> run<T>(Future<T> Function() action);
}
