#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PUBLISH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$PUBLISH_DIR/../.." && pwd)"
BLOCKERS=0
WARNINGS=0

pass() {
  echo "PASS: $1"
}

warn() {
  echo "WARN: $1"
  WARNINGS=$((WARNINGS + 1))
}

block() {
  echo "BLOCKER: $1"
  BLOCKERS=$((BLOCKERS + 1))
}

single_line_chars() {
  tr -d '\r\n' < "$1" | wc -m | tr -d ' '
}

single_line_bytes() {
  tr -d '\r\n' < "$1" | wc -c | tr -d ' '
}

check_max_chars() {
  local file="$1"
  local maximum="$2"
  local label="$3"
  local count
  count="$(single_line_chars "$file")"
  if [ "$count" -le "$maximum" ]; then
    pass "$label is $count/$maximum characters"
  else
    block "$label is $count characters; maximum is $maximum ($file)"
  fi
}

cd "$PROJECT_DIR" || exit 2

XCODE_LINE="$(xcodebuild -version 2>/dev/null | head -n 1)"
XCODE_MAJOR="$(echo "$XCODE_LINE" | awk '{split($2, version, "."); print version[1]}')"
if [ -n "$XCODE_MAJOR" ] && [ "$XCODE_MAJOR" -ge 26 ]; then
  pass "$XCODE_LINE satisfies the current upload minimum"
else
  block "Xcode 26+ is required; found ${XCODE_LINE:-unknown}"
fi

if rg -q 'PRODUCT_BUNDLE_IDENTIFIER = com\.sheanzero\.happypocket\.app;' ios/Runner.xcodeproj/project.pbxproj; then
  pass "Runner Bundle ID matches com.sheanzero.happypocket.app"
else
  block "Runner Bundle ID does not match the release package"
fi

if rg -q "^platform :ios, '15\.0'$" ios/Podfile \
  && rg -q 'IPHONEOS_DEPLOYMENT_TARGET = 15\.0;' ios/Runner.xcodeproj/project.pbxproj; then
  pass "Podfile and Xcode deployment targets are both iOS 15.0"
else
  block "Podfile and Xcode deployment targets must both be iOS 15.0"
fi

if rg -q 'iOS 15' "$PUBLISH_DIR/RELEASE_GATES.md" \
  && rg -q 'iOS 15' "$PUBLISH_DIR/intro/en/app-introduction.md" \
  && rg -q 'iOS 15' "$PUBLISH_DIR/intro/ja/app-introduction.md" \
  && ! rg -q 'iOS 14' "$PUBLISH_DIR/RELEASE_GATES.md" "$PUBLISH_DIR/intro"; then
  pass "iOS release materials declare iOS 15 and contain no iOS 14 support claim"
else
  block "iOS release materials must consistently declare iOS 15"
fi

if rg -q 'TARGETED_DEVICE_FAMILY = "1,2";' ios/Runner.xcodeproj/project.pbxproj; then
  warn "Target supports iPhone and iPad; 13-inch iPad screenshots and QA are mandatory"
fi

APP_ICON="$PUBLISH_DIR/assets/app-icon/AppIcon-1024.png"
if [ -f "$APP_ICON" ]; then
  ICON_INFO="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$APP_ICON" 2>/dev/null)"
  if echo "$ICON_INFO" | rg -q 'pixelWidth: 1024' \
    && echo "$ICON_INFO" | rg -q 'pixelHeight: 1024' \
    && echo "$ICON_INFO" | rg -q 'hasAlpha: no'; then
    pass "App Store icon is 1024x1024 with no Alpha"
  else
    block "App Store icon must be 1024x1024 with no Alpha"
  fi
else
  block "missing App Store icon: $APP_ICON"
fi

for locale in ja zh-Hans en-US; do
  META_DIR="$PUBLISH_DIR/metadata/$locale"
  check_max_chars "$META_DIR/name.txt" 30 "$locale app name"
  check_max_chars "$META_DIR/subtitle.txt" 30 "$locale subtitle"
  check_max_chars "$META_DIR/promotional_text.txt" 170 "$locale promotional text"

  DESCRIPTION_CHARS="$(wc -m < "$META_DIR/description.txt" | tr -d ' ')"
  if [ "$DESCRIPTION_CHARS" -le 4000 ]; then
    pass "$locale description is $DESCRIPTION_CHARS/4000 characters"
  else
    block "$locale description exceeds 4000 characters"
  fi

  KEYWORD_BYTES="$(single_line_bytes "$META_DIR/keywords.txt")"
  if [ "$KEYWORD_BYTES" -le 100 ]; then
    pass "$locale keywords are $KEYWORD_BYTES/100 bytes"
  else
    block "$locale keywords are $KEYWORD_BYTES bytes; maximum is 100"
  fi

  if rg -q '__REQUIRED_' "$META_DIR/support_url.txt"; then
    block "$locale support URL is still a required placeholder"
  elif rg -q '^https://' "$META_DIR/support_url.txt"; then
    pass "$locale support URL uses HTTPS"
  else
    block "$locale support URL is missing or not HTTPS"
  fi

  if rg -q '__REQUIRED_' "$META_DIR/privacy_url.txt"; then
    block "$locale privacy policy URL is still a required placeholder"
  fi
done

if rg -n 'support@example\.com|\[上线前填真实值\]|DRAFT MARKER|草案マーカー|草案标记|IMPORTANT / DRAFT|重要・草案|重要·草案' assets/legal >/dev/null; then
  block "shipping legal assets still contain draft markers or required placeholders"
else
  pass "shipping legal assets contain no known draft markers/placeholders"
fi

if rg -q 'Everything stays on your device|Never sent to the cloud' lib/l10n/app_en.arb; then
  block "onboarding still contains absolute local-only/cloud-free claims"
fi

if [ -f ios/Runner/PrivacyInfo.xcprivacy ]; then
  if plutil -lint ios/Runner/PrivacyInfo.xcprivacy >/dev/null; then
    pass "Runner privacy manifest exists and is valid plist"
  else
    block "Runner privacy manifest exists but is not a valid plist"
  fi
else
  block "Runner has no app-level PrivacyInfo.xcprivacy; finalize from Xcode Privacy Report"
fi

if plutil -lint "$PUBLISH_DIR/privacy/PrivacyInfo.xcprivacy.template" >/dev/null; then
  pass "privacy manifest template is valid plist"
else
  block "privacy manifest template is invalid"
fi

if rg -q '<key>NSPhotoLibraryUsageDescription</key>' ios/Runner/Info.plist; then
  pass "Photo Library usage description is present"
else
  block "Photo Library usage description is absent while avatar picker reads the photo library"
fi

READY_IMAGE_COUNT="$(find "$PUBLISH_DIR/screenshots/ready" -type f -name '*.png' | wc -l | tr -d ' ')"
if [ "$READY_IMAGE_COUNT" -eq 30 ]; then
  pass "30 final screenshots are present (3 locales x 2 devices x 5)"
else
  block "expected 30 final screenshots; found $READY_IMAGE_COUNT"
fi

if rg -n '__REQUIRED_' "$PUBLISH_DIR/review/app_review_notes_en.txt" >/dev/null; then
  block "App Review notes still contain required contact placeholders"
fi

echo "Result: $BLOCKERS blocker(s), $WARNINGS warning(s)"
if [ "$BLOCKERS" -gt 0 ]; then
  exit 1
fi
exit 0
