#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
derived_data="${TMPDIR:-/tmp}/netmeter-xcode-derived-data"
product="$derived_data/Build/Products/Release/NetMeter.app"
output="$HOME/Library/Application Support/NetMeter/Builds/NetMeter.app"
workspace_link="$project_root/dist/NetMeter.app"

xcodebuild \
  -project "$project_root/NetMeter.xcodeproj" \
  -scheme NetMeter \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet build

if [[ ! -d "$product" ]]; then
  echo "Release build did not produce NetMeter.app" >&2
  exit 1
fi

mkdir -p "$(dirname "$output")" "$project_root/dist"
rm -rf "$output"
ditto "$product" "$output"
xattr -cr "$output"
codesign --force --deep --sign - "$output"
codesign --verify --deep --strict "$output"
rm -rf "$workspace_link"
ln -s "$output" "$workspace_link"

echo "Release app: $workspace_link"
