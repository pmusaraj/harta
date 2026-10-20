#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Usage: scripts/testflight.sh <archive|export|upload> <build-number>

  archive  Build a signed Release archive for iOS.
  export   Archive and export an App Store IPA locally.
  upload   Archive and upload to App Store Connect for TestFlight.

Use an unused, increasing build number (1–9999) for each upload.
Artifacts and logs: .build/testflight/<build-number>/<timestamp>/
Optional API credentials are read from .env.testflight or the environment.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ $# != 2 ]]; then usage >&2; exit 1; fi
ACTION="$1"
BUILD_NUMBER="$2"
case "$ACTION" in archive|export|upload) ;; *) usage >&2; exit 1 ;; esac
if [[ ! "$BUILD_NUMBER" =~ ^[1-9][0-9]{0,3}$ ]]; then
  echo "Build number must be an integer from 1 to 9999." >&2
  exit 1
fi

if [[ -f .env.testflight ]]; then source .env.testflight; fi
AUTH=(-allowProvisioningUpdates)
if [[ -n "${ASC_KEY_PATH:-}${ASC_KEY_ID:-}${ASC_ISSUER_ID:-}" ]]; then
  if [[ -z "${ASC_KEY_PATH:-}" || -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" ]]; then
    echo "Set ASC_KEY_PATH, ASC_KEY_ID, and ASC_ISSUER_ID together." >&2
    exit 1
  fi
  if [[ ! -r "$ASC_KEY_PATH" ]]; then
    echo "ASC_KEY_PATH must point to a readable .p8 key." >&2
    exit 1
  fi
  AUTH+=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

command -v xcodegen >/dev/null || { echo "Install XcodeGen: brew install xcodegen" >&2; exit 1; }
xcodegen generate
OUTPUT="$ROOT/.build/testflight/$BUILD_NUMBER/$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$OUTPUT"
ARCHIVE="$OUTPUT/Harta.xcarchive"

xcodebuild -project Harta.xcodeproj -scheme Harta -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  -derivedDataPath "$ROOT/.build/TestFlightDerivedData" \
  -onlyUsePackageVersionsFromResolvedFile \
  "${AUTH[@]}" "CURRENT_PROJECT_VERSION=$BUILD_NUMBER" archive \
  2>&1 | tee "$OUTPUT/archive.log"

if [[ "$ACTION" == archive ]]; then
  echo "Archive ready: $ARCHIVE"
  exit 0
fi

DESTINATION=export
if [[ "$ACTION" == upload ]]; then DESTINATION=upload; fi
cat > "$OUTPUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$DESTINATION</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
  <key>testFlightInternalTestingOnly</key><false/>
</dict></plist>
EOF

xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportPath "$OUTPUT/export" -exportOptionsPlist "$OUTPUT/ExportOptions.plist" \
  "${AUTH[@]}" 2>&1 | tee "$OUTPUT/$ACTION.log"
echo "Completed $ACTION for build $BUILD_NUMBER. Artifacts: $OUTPUT"
