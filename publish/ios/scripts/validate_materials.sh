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

IOS_RELEASE_MATERIALS=(
  "$PUBLISH_DIR/README.md"
  "$PUBLISH_DIR/APP_STORE_RELEASE.md"
  "$PUBLISH_DIR/intro/en/app-introduction.md"
  "$PUBLISH_DIR/intro/ja/app-introduction.md"
)
IOS_VERSION_MISMATCH=0
for material in "${IOS_RELEASE_MATERIALS[@]}"; do
  if rg -q 'iOS 15' "$material" && ! rg -q 'iOS 14' "$material"; then
    pass "$(basename "$material") declares iOS 15 and no iOS 14 support claim"
  else
    block "iOS release material must declare iOS 15 and contain no iOS 14 support claim: $material"
    IOS_VERSION_MISMATCH=1
  fi
done

if [ "$IOS_VERSION_MISMATCH" -eq 0 ]; then
  pass "iOS release materials consistently declare iOS 15"
fi

if rg -q 'TARGETED_DEVICE_FAMILY = 1;' ios/Runner.xcodeproj/project.pbxproj \
  && ! rg -q 'TARGETED_DEVICE_FAMILY = "1,2";' ios/Runner.xcodeproj/project.pbxproj; then
  pass "Runner target supports iPhone only"
else
  block "Runner target must support iPhone only"
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

LEGAL_SNAPSHOT_DIR="$PUBLISH_DIR/legal/current"
if rg -n 'support@example\.com|\[上线前填真实值\]|DRAFT MARKER|草案マーカー|草案标记|IMPORTANT / DRAFT|重要・草案|重要·草案' assets/legal "$LEGAL_SNAPSHOT_DIR" >/dev/null; then
  block "shipping legal assets still contain draft markers or required placeholders"
else
  pass "shipping legal assets contain no known draft markers/placeholders"
fi

LEGAL_MISMATCH=0
for legal_file in assets/legal/*.html; do
  legal_name="$(basename "$legal_file")"
  if ! cmp -s "$legal_file" "$LEGAL_SNAPSHOT_DIR/$legal_name"; then
    block "shipping legal snapshot differs from app asset: $legal_name"
    LEGAL_MISMATCH=1
  fi
done
if [ "$LEGAL_MISMATCH" -eq 0 ]; then
  pass "shipping legal snapshot exactly matches all app legal assets"
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

if rg -q 'PrivacyInfo\.xcprivacy in Resources' ios/Runner.xcodeproj/project.pbxproj; then
  pass "Runner target bundles the privacy manifest"
else
  block "Runner target does not bundle PrivacyInfo.xcprivacy"
fi

MANIFEST_DUMP="$(plutil -p ios/Runner/PrivacyInfo.xcprivacy 2>/dev/null)"
if echo "$MANIFEST_DUMP" | rg -q '"NSPrivacyTracking" => false' \
  && echo "$MANIFEST_DUMP" | rg -q '"NSPrivacyAccessedAPITypes" => \['; then
  pass "Runner privacy manifest declares no tracking or app-owned Required Reason API"
else
  block "Runner privacy manifest must explicitly disable tracking and keep app-owned Required Reason APIs evidence-based"
fi

for data_type in Name UserID DeviceID OtherUserContent; do
  if ! echo "$MANIFEST_DUMP" | rg -q "NSPrivacyCollectedDataType${data_type}"; then
    block "Runner privacy manifest is missing evidenced collected data type: $data_type"
  fi
done

if echo "$MANIFEST_DUMP" | rg -q 'NSPrivacyCollectedDataType(PhotosorVideos|PurchaseHistory|OtherFinancialInfo)'; then
  block "Runner privacy manifest overdeclares unsupported photo or financial collection"
fi

if plutil -lint "$PUBLISH_DIR/privacy/PrivacyInfo.xcprivacy.template" >/dev/null; then
  pass "privacy manifest template is valid plist"
else
  block "privacy manifest template is invalid"
fi

for permission_key in NSCameraUsageDescription NSLocationWhenInUseUsageDescription NSPhotoLibraryUsageDescription; do
  if rg -q "<key>${permission_key}</key>" ios/Runner/Info.plist; then
    pass "$permission_key is present"
  else
    block "$permission_key is absent from the shipping Info.plist"
  fi
done

READY_IMAGE_COUNT="$(find "$PUBLISH_DIR/screenshots/ready" -type f -name '*.png' | wc -l | tr -d ' ')"
if [ "$READY_IMAGE_COUNT" -eq 10 ]; then
  pass "10 Japanese iPhone marketing screenshots are present"
else
  block "expected 10 Japanese iPhone screenshots; found $READY_IMAGE_COUNT"
fi

REVIEW_NOTES="$PUBLISH_DIR/review/app_review_notes_en.txt"
REVIEW_VALUES="$PUBLISH_DIR/REQUIRED_VALUES.env.example"
if rg -n '__REQUIRED_REVIEW_CONTACT_' "$REVIEW_NOTES" "$REVIEW_VALUES" >/dev/null; then
  block "App Review contact still contains required placeholders"
elif rg -q 'Representative 張欣, ナープ株式会社, support@napu\.co\.jp, \+81368597235\.' "$REVIEW_NOTES" \
  && rg -q '^REVIEW_FIRST_NAME="欣"$' "$REVIEW_VALUES" \
  && rg -q '^REVIEW_LAST_NAME="張"$' "$REVIEW_VALUES" \
  && rg -q '^REVIEW_COMPANY="ナープ株式会社"$' "$REVIEW_VALUES" \
  && rg -q '^REVIEW_EMAIL="support@napu\.co\.jp"$' "$REVIEW_VALUES" \
  && rg -q '^REVIEW_PHONE="\+81368597235"$' "$REVIEW_VALUES"; then
  pass "App Review contact uses approved operator details"
else
  block "App Review contact does not match approved operator details"
fi

echo "Result: $BLOCKERS blocker(s), $WARNINGS warning(s)"
if [ "$BLOCKERS" -gt 0 ]; then
  exit 1
fi
exit 0
