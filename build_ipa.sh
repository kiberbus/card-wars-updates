#!/bin/sh
# The unsigned iOS app from the Xcode project Godot exports (preset "iOS", tools/publish.ps1):
#   sh build_ipa.sh <zip or folder with CardWars.xcodeproj> <out .ipa>
# Needs a Mac with Xcode. GitHub Actions runs it (tools/ios_workflow.yml, in the updates repo);
# on your own Mac the same command works. The .ipa is not signed: whoever installs it signs it
# with their own Apple account (Sideloadly, AltStore and the like).
set -e
src="$1"
out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
work="$(mktemp -d)"
if [ -f "$src" ]; then
    unzip -q "$src" -d "$work/proj"
else
    cp -R "$src" "$work/proj"
fi
proj="$(dirname "$(find "$work/proj" -maxdepth 3 -name '*.xcodeproj' | head -1)")"
cd "$proj"
name="$(basename *.xcodeproj .xcodeproj)"
xcodebuild -project "$name.xcodeproj" -scheme "$name" -configuration Release -sdk iphoneos \
    -destination "generic/platform=iOS" -derivedDataPath "$work/build" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" build
app="$(find "$work/build/Build/Products" -maxdepth 2 -name '*.app' | head -1)"
mkdir -p "$work/ipa/Payload"
cp -R "$app" "$work/ipa/Payload/"
rm -f "$out"
(cd "$work/ipa" && zip -qry "$out" Payload)
rm -rf "$work"
echo "built $out"
