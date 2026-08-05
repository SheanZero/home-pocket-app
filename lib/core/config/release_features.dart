/// Product capabilities intentionally held back from the first public release.
///
/// Keeping these switches centralized makes the dormant implementation easy to
/// reactivate in a later, separately reviewed release without exposing partial
/// controls or starting third-party services in the meantime.
abstract final class ReleaseFeatures {
  static const bool pushNotifications = false;
  static const bool sponsorship = false;
}
