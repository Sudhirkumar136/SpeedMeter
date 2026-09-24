#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_app="$(readlink "$project_root/dist/NetMeter.app" 2>/dev/null || true)"
destination="/Applications/NetMeter.app"

if [[ -z "$source_app" || ! -d "$source_app" ]]; then
  echo "Build the app first with ./scripts/build-release.sh" >&2
  exit 1
fi

if [[ ! -w /Applications ]]; then
  echo "This account cannot write to /Applications. Run this script with sudo to install NetMeter." >&2
  exit 1
fi

if [[ -e "$destination" ]]; then
  rm -rf "$destination"
fi
ditto "$source_app" "$destination"
xattr -cr "$destination"
codesign --verify --deep --strict "$destination"

echo "Installed: $destination"
