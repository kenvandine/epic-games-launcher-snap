#!/bin/bash
# Update snap/snapcraft.yaml to the latest Epic Games Launcher AppImage.
# Prints "updated=true|false" and "version=<ver>" lines (suitable for $GITHUB_OUTPUT).
set -euo pipefail

YAML="${YAML:-snap/snapcraft.yaml}"
API="https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncher-x86_64.AppImage"

location="$(curl -fsSI "$API" | tr -d '\r' | awk 'tolower($1)=="location:"{print $2}')"
raw="$(sed -n 's|.*/EGLv2/\([^/]*\)/Linux/.*|\1|p' <<<"$location")"
if [ -z "$raw" ]; then
    echo "Could not parse build id from redirect: $location" >&2
    exit 1
fi
# 0.96.0%2Bg2fade97 -> 0.96.0
version="${raw%%%2B*}"

current="$(sed -n 's|.*/EGLv2/\([^/]*\)/Linux/.*|\1|p' "$YAML" | head -n1)"
if [ "$raw" = "$current" ]; then
    echo "Already at $raw" >&2
    echo "updated=false"
    echo "version=$version"
    exit 0
fi

url="https://content-download-egs.distro.on.epicgames.com/Builds/EGLv2/${raw}/Linux/EpicGamesLauncher-x86_64.AppImage"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
curl -fsSL --retry 3 -o "$tmp" "$url"
sha="$(sha256sum "$tmp" | cut -d' ' -f1)"

sed -i \
    -e "s|^version: .*|version: \"${version}\"|" \
    -e "s|/Builds/EGLv2/[^/]*/Linux/|/Builds/EGLv2/${raw}/Linux/|" \
    -e "s|echo \"[0-9a-f]\{64\}  EpicGamesLauncher.AppImage\"|echo \"${sha}  EpicGamesLauncher.AppImage\"|" \
    "$YAML"

echo "Updated $current -> $raw ($sha)" >&2
echo "updated=true"
echo "version=$version"
