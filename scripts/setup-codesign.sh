#!/usr/bin/env bash
# Install an Apple signing identity + provisioning profile into a temporary
# keychain so xcodebuild can sign device builds in CI.
#
# Required env (typically wired from GitHub Actions secrets):
#   BUILD_CERT_P12_BASE64               base64-encoded .p12 (cert + private key)
#   BUILD_CERT_PASSWORD                 password for the .p12
#   BUILD_PROVISIONING_PROFILE_BASE64   base64-encoded .mobileprovision
#   KEYCHAIN_PASSWORD                   password for the temporary keychain
#
# On success, exports profile metadata to $GITHUB_ENV so subsequent xcodebuild
# steps can reference it via ${{ env.PROFILE_NAME }} / TEAM_ID etc:
#   PROFILE_NAME, PROFILE_UUID, TEAM_ID, BUNDLE_ID
set -euo pipefail

require() {
  if [ -z "${!1:-}" ]; then echo "missing env: $1" >&2; exit 1; fi
}
require BUILD_CERT_P12_BASE64
require BUILD_CERT_PASSWORD
require BUILD_PROVISIONING_PROFILE_BASE64
require KEYCHAIN_PASSWORD

KEYCHAIN_NAME="build.keychain"
TMP="${RUNNER_TEMP:-/tmp}"
CERT_PATH="$TMP/build_cert.p12"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
PROFILE_PATH="$PROFILE_DIR/build.mobileprovision"
PROFILE_PLIST="$TMP/profile.plist"

# Decode secrets to disk
echo "$BUILD_CERT_P12_BASE64" | base64 --decode > "$CERT_PATH"
mkdir -p "$PROFILE_DIR"
echo "$BUILD_PROVISIONING_PROFILE_BASE64" | base64 --decode > "$PROFILE_PATH"

# Replace any stale keychain from a previous run
security delete-keychain "$KEYCHAIN_NAME" 2>/dev/null || true
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security set-keychain-settings -lut 21600 "$KEYCHAIN_NAME"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"

# Make the temp keychain the first one xcodebuild searches
existing=$(security list-keychains -d user | tr -d '"' | xargs)
security list-keychains -d user -s "$KEYCHAIN_NAME" $existing

# Import cert; allow codesign + security to read the key without UI prompt
security import "$CERT_PATH" -k "$KEYCHAIN_NAME" -P "$BUILD_CERT_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple:,codesign: \
  -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME" >/dev/null

# Extract profile metadata for downstream xcodebuild flags
security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST"
PROFILE_NAME=$(plutil -extract Name raw "$PROFILE_PLIST")
PROFILE_UUID=$(plutil -extract UUID raw "$PROFILE_PLIST")
TEAM_ID=$(plutil -extract TeamIdentifier.0 raw "$PROFILE_PLIST")
BUNDLE_ID=$(plutil -extract Entitlements.application-identifier raw "$PROFILE_PLIST" \
  | sed -E "s/^${TEAM_ID}\.//")

echo "::notice::installed signing: profile='$PROFILE_NAME' uuid=$PROFILE_UUID team=$TEAM_ID bundle=$BUNDLE_ID"

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "PROFILE_NAME=$PROFILE_NAME"
    echo "PROFILE_UUID=$PROFILE_UUID"
    echo "TEAM_ID=$TEAM_ID"
    echo "BUNDLE_ID=$BUNDLE_ID"
  } >> "$GITHUB_ENV"
fi

rm -f "$CERT_PATH" "$PROFILE_PLIST"
