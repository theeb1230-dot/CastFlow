#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <ipa-path> <unsigned|signed>" >&2
  exit 64
fi

IPA="$1"
MODE="$2"

if [[ "$MODE" != "unsigned" && "$MODE" != "signed" ]]; then
  echo "invalid validation mode: $MODE" >&2
  exit 64
fi

test -s "$IPA"
unzip -tq "$IPA" >/dev/null

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
unzip -q "$IPA" -d "$TMP_DIR"

APP="$(find "$TMP_DIR/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
test -n "$APP"
test -d "$APP"

EXTENSION="$APP/PlugIns/BroadcastUploadExtension.appex"
test -d "$EXTENSION"

PLIST_BUDDY="/usr/libexec/PlistBuddy"
test -x "$PLIST_BUDDY"

APP_PLIST="$APP/Info.plist"
EXT_PLIST="$EXTENSION/Info.plist"
test -f "$APP_PLIST"
test -f "$EXT_PLIST"

APP_BUNDLE="$("$PLIST_BUDDY" -c 'Print :CFBundleIdentifier' "$APP_PLIST")"
APP_VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$APP_PLIST")"
APP_BUILD="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$APP_PLIST")"

EXT_BUNDLE="$("$PLIST_BUDDY" -c 'Print :CFBundleIdentifier' "$EXT_PLIST")"
EXT_VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$EXT_PLIST")"
EXT_BUILD="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$EXT_PLIST")"
EXT_POINT="$("$PLIST_BUDDY" -c 'Print :NSExtension:NSExtensionPointIdentifier' "$EXT_PLIST")"

test "$APP_BUNDLE" = "com.castflow.castflow"
test "$EXT_BUNDLE" = "com.castflow.castflow.BroadcastUploadExtension"
test "$APP_VERSION" = "1.0.2"
test "$APP_BUILD" = "3"
test "$EXT_VERSION" = "$APP_VERSION"
test "$EXT_BUILD" = "$APP_BUILD"
test "$EXT_POINT" = "com.apple.broadcast-services-upload"

test -x "$APP/Runner"
test -x "$EXTENSION/BroadcastUploadExtension"

if [[ "$MODE" = "unsigned" ]]; then
  if codesign -d "$APP" >/dev/null 2>&1; then
    echo "unsigned IPA gate failed: Runner.app unexpectedly has a code signature" >&2
    exit 1
  fi
  if codesign -d "$EXTENSION" >/dev/null 2>&1; then
    echo "unsigned IPA gate failed: ReplayKit extension unexpectedly has a code signature" >&2
    exit 1
  fi
else
  test -f "$APP/embedded.mobileprovision"
  test -f "$EXTENSION/embedded.mobileprovision"
  codesign --verify --deep --strict "$APP"
  codesign --verify --strict "$EXTENSION"

  APP_ENTITLEMENTS="$TMP_DIR/app-entitlements.plist"
  EXT_ENTITLEMENTS="$TMP_DIR/extension-entitlements.plist"
  codesign -d --entitlements :- "$APP" >"$APP_ENTITLEMENTS" 2>/dev/null
  codesign -d --entitlements :- "$EXTENSION" >"$EXT_ENTITLEMENTS" 2>/dev/null

  grep -q "group.com.castflow.shared" "$APP_ENTITLEMENTS"
  grep -q "group.com.castflow.shared" "$EXT_ENTITLEMENTS"
fi

echo "IPA validation passed: mode=$MODE version=$APP_VERSION+$APP_BUILD"
