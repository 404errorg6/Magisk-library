#!/bin/bash

# Prompt for destination folder
echo "Where do you want to save the downloaded modules?"
echo "1) Current directory (./Modules)"
echo "2) /storage/emulated/0/Download/Modules"
echo -n "Choose [1/2] (default: 1): "
read loc_choice
loc_choice="${loc_choice:-1}"

if [[ "$loc_choice" == "2" ]]; then
  dest="/storage/emulated/0/Download/Modules"
else
  dest="./Modules"
fi

mkdir -p "$dest"
echo "📂 Modules will be saved to: $dest"
echo

# List of modules (name|URL)
modules=(
  "abootloop|https://github.com/Magisk-Modules-Alt-Repo/abootloop/releases/latest/download/abootloop.zip"
  "LSPosed (latest)|https://api.github.com/repos/LSPosed/LSPosed/releases/latest"
  "Zygisk Next v1.2.8|https://github.com/Dr-TSNG/ZygiskNext/releases/download/v1.2.8/Zygisk-Next-1.2.8-512-4b5d6ad-release.zip"
)

download_module() {
  name="$1"
  url="$2"

  echo -n "Download $name? [Y/n]: "
  read answer
  answer="${answer:-y}"

  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$url" == *api.github.com* ]]; then
      echo "Fetching latest $name from GitHub API..."
      asset_url=$(curl -s "$url" | grep browser_download_url | grep zygisk-release | cut -d '"' -f 4)
      filename=$(basename "$asset_url")
    else
      asset_url="$url"
      filename=$(basename "$url")
    fi

    echo "⬇️ Downloading $filename..."
    curl -L -o "$dest/$filename" "$asset_url"
    echo "✅ $name downloaded as $dest/$filename"
  else
    echo "❌ Skipped $name"
  fi
}

# Loop through modules
for entry in "${modules[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  download_module "$name" "$url"
done

