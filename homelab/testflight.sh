#!/bin/bash
# Neuen Build von HomeLabBooks für TestFlight bauen und hochladen: Web-Teil bauen, iOS-Projekt
# abgleichen, Build-Nummer +1, Archiv, Upload. Aufruf im Repo-Wurzelverzeichnis: homelab/testflight.sh [--nur-archiv]
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8          # CocoaPods bricht sonst ab (Encoding-Fehler)
# Anmeldung über den App-Store-Connect-API-Schlüssel (derselbe wie bei HomeLabMusic, nicht in Git)
AUTH=()
if [ -f homelab/asc.env ]; then
  source homelab/asc.env
  AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi
npm ci --no-audit --no-fund --loglevel=error
npm run generate >/dev/null
npx cap sync ios >/dev/null
(cd ios/App && pod install >/dev/null)

P=ios/App/App.xcodeproj/project.pbxproj
alt=$(grep -m1 -o 'CURRENT_PROJECT_VERSION = [0-9]*' "$P" | grep -o '[0-9]*$')
neu=$((alt + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = $alt;/CURRENT_PROJECT_VERSION = $neu;/g" "$P"
echo "Build $neu"
rm -rf .build-dd/HomeLabBooks.xcarchive .build-dd/export
xcodebuild -workspace ios/App/App.xcworkspace -scheme App -configuration Release -destination "generic/platform=iOS" \
  -archivePath .build-dd/HomeLabBooks.xcarchive -derivedDataPath .build-dd \
  -allowProvisioningUpdates "${AUTH[@]}" -quiet archive
if [ "${1:-}" = "--nur-archiv" ]; then git checkout -- "$P"; echo "Archiv fertig (ohne Upload)"; exit 0; fi
log=$(mktemp)
if ! xcodebuild -exportArchive -archivePath .build-dd/HomeLabBooks.xcarchive \
  -exportOptionsPlist homelab/ExportOptions.plist -exportPath .build-dd/export -allowProvisioningUpdates "${AUTH[@]}" >"$log" 2>&1 \
  || ! grep -q "Upload succeeded" "$log"; then
  grep -iE "error|fail" "$log" | head -5
  git checkout -- "$P"                                    # Build-Nummer zurück, nichts committen
  echo "UPLOAD FEHLGESCHLAGEN (Build $neu). Prüfen: homelab/asc.env, App in App Store Connect angelegt?"
  exit 1
fi
git commit -q -m "TestFlight: Build $neu" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" "$P" && echo "Build $neu hochgeladen und committet"
