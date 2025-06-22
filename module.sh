#!/bin/bash

# Detect architecture keyword
arch=$(uname -m)
case "$arch" in
  aarch64|armv8*) arch_keyword="arm64" ;;
  armv7l|arm*)    arch_keyword="arm" ;;
  x86_64)         arch_keyword="x86_64" ;;
  i*86)           arch_keyword="x86" ;;
  *)              arch_keyword="" ;;
esac

echo "Detected architecture: $arch → keyword: '$arch_keyword'"
echo

# Choose destination
echo "Where do you want to save the downloaded modules?"
echo "1) Current directory (./Modules)"
echo "2) /storage/emulated/0/Download/Modules"
echo -n "Choose [1/2] (default: 1): "
read -n 1 loc_choice
echo
loc_choice="${loc_choice:-1}"

if [[ "$loc_choice" == "2" ]]; then
  dest="/storage/emulated/0/Download/Modules"
else
  dest="./Modules"
fi

mkdir -p "$dest"
echo "Modules will be saved to: $dest"
echo

# Modules: name|GitHub API URL
modules=(
  "abootloop|https://api.github.com/repos/Magisk-Modules-Alt-Repo/abootloop/releases/latest"
  "LSPosed|https://api.github.com/repos/LSPosed/LSPosed/releases/latest"
  "Zygisk Next|https://api.github.com/repos/Dr-TSNG/ZygiskNext/releases/latest"
  "PlayIntegrityFix|https://api.github.com/repos/chiteroman/PlayIntegrityFix/releases/latest"
  "ViPER4Android|https://api.github.com/repos/AndroidAudioMods/ViPER4Android/releases/latest"
)

download_module() {
  local name="$1"
  local api_url="$2"

  echo -n "Download $name? [Y/n]: "
  read -n 1 answer
  echo
  answer="${answer:-y}"
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Skipped $name"
    return
  fi

  echo "Fetching latest release info for $name..."

  # Fetch release JSON once
  release_json=$(curl -s "$api_url")

  # Try to find arch-specific zip file first
  asset_url=$(echo "$release_json" | grep browser_download_url | grep '.zip' | grep -i "$arch_keyword" | cut -d '"' -f 4 | head -n1)

  # If no match, fallback to any .zip
  if [[ -z "$asset_url" ]]; then
    asset_url=$(echo "$release_json" | grep browser_download_url | grep '.zip' | cut -d '"' -f 4 | head -n1)
  fi

  if [[ -z "$asset_url" ]]; then
    echo "No .zip file found for $name"
  else
    filename=$(basename "$asset_url")
    echo "Downloading $filename..."
    curl -L -# -o "$dest/$filename" "$asset_url"
    echo "Downloaded to $dest/$filename"
    echo
  fi

  # Special case: ViPER4Android needs APK as well
  if [[ "$name" == "ViPER4Android" ]]; then
    apk_url=$(echo "$release_json" | grep browser_download_url | grep '.apk' | cut -d '"' -f 4 | head -n1)
    if [[ -n "$apk_url" ]]; then
      apk_file=$(basename "$apk_url")
      echo "Downloading companion APK: $apk_file..."
      curl -L -# -o "$dest/$apk_file" "$apk_url"
      echo "Downloaded to $dest/$apk_file"
    else
      echo "No APK found for $name"
    fi
    echo
  fi
}

# Loop and process each module
for entry in "${modules[@]}"; do
  IFS='|' read -r name api_url <<< "$entry"
  download_module "$name" "$api_url"
done
