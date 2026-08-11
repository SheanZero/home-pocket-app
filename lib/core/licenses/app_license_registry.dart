import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef _BundledLicense = ({List<String> packages, String assetPath});

/// Package labels manually added on top of Flutter's generated Pub notices.
const Set<String> bundledThirdPartyPackageNames = {
  'Roboto Mono',
  'SQLCipher',
  'CwlCatchException (iOS)',
  'DKCamera (iOS)',
  'DKImagePickerController (iOS)',
  'DKPhotoGallery (iOS)',
  'SDWebImage (iOS)',
  'SwiftyGif (iOS)',
  'TOCropViewController (iOS)',
};

/// Swift Package Manager identities covered by the bundled native notices.
///
/// The architecture test compares this set with Package.resolved so a future
/// iOS dependency cannot silently ship without an acknowledgement.
const Set<String> bundledIosSwiftPackageIdentities = {
  'cwlcatchexception',
  'dkcamera',
  'dkimagepickercontroller',
  'dkphotogallery',
  'sdwebimage',
  'swiftygif',
  'tocropviewcontroller',
};

/// Reviewed revisions whose license texts are copied into app assets.
const Map<String, String> bundledIosSwiftPackageRevisions = {
  'cwlcatchexception': '07b2ba21d361c223e25e3c1e924288742923f08c',
  'dkcamera': '5c691d11014b910aff69f960475d70e65d9dcc96',
  'dkimagepickercontroller': '0bdfeacefa308545adde07bef86e349186335915',
  'dkphotogallery': '311c1bc7a94f1538f82773a79c84374b12a2ef3d',
  'sdwebimage': '2de3a496eaf6df9a1312862adcfd54acd73c39c0',
  'swiftygif': '4430cbc148baa3907651d40562d96325426f409a',
  'tocropviewcontroller': 'd4a6d8100f4b886fdbc8ae399bf144ff3e9afb7e',
};

const List<_BundledLicense> _bundledLicenses = [
  (packages: ['Roboto Mono'], assetPath: 'assets/fonts/RobotoMono-OFL.txt'),
  (packages: ['SQLCipher'], assetPath: 'assets/licenses/native/sqlcipher.txt'),
  (
    packages: ['CwlCatchException (iOS)'],
    assetPath: 'assets/licenses/native/cwl_catch_exception.txt',
  ),
  (
    packages: [
      'DKCamera (iOS)',
      'DKImagePickerController (iOS)',
      'DKPhotoGallery (iOS)',
    ],
    assetPath: 'assets/licenses/native/dk_image_suite.txt',
  ),
  (
    packages: ['SDWebImage (iOS)'],
    assetPath: 'assets/licenses/native/sdwebimage.txt',
  ),
  (
    packages: ['SwiftyGif (iOS)'],
    assetPath: 'assets/licenses/native/swiftygif.txt',
  ),
  (
    packages: ['TOCropViewController (iOS)'],
    assetPath: 'assets/licenses/native/to_crop_view_controller.txt',
  ),
];

bool _bundledLicensesRegistered = false;

/// Adds non-Pub notices to the same registry used by [LicensePage].
///
/// Flutter automatically collects root LICENSE files from Dart/Flutter
/// packages. It does not collect the app's bundled font license or licenses
/// from native Swift packages, so those are registered explicitly here.
void registerBundledThirdPartyLicenses() {
  if (_bundledLicensesRegistered) return;
  _bundledLicensesRegistered = true;

  LicenseRegistry.addLicense(() async* {
    for (final license in _bundledLicenses) {
      final text = await rootBundle.loadString(license.assetPath);
      yield LicenseEntryWithLineBreaks(license.packages, text);
    }
  });
}
