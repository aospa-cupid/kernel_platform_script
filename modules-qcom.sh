#!/bin/bash

# Prompt to change directory
read -p "Enter the directory where the script should run: " target_dir
if [ ! -d "$target_dir" ]; then
  mkdir -p "$target_dir"
  echo "Directory $target_dir created."
fi

cd "$target_dir" || { echo "Failed to change to directory $target_dir. Exiting."; exit 1; }

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
  git init
  git commit --allow-empty -m "modules: Initial empty repository"
  echo "Initialized empty git repository and made initial commit."
fi

# Function to get the latest tag from a remote repository
get_latest_tag() {
  url=$1
  prefix=$2

  # Fetch all tags from the remote and extract relevant versions
  git ls-remote --tags $url | grep -o 'refs/tags/[^\^]*' | awk -F/ '{print $3}' | grep "$prefix" | grep "lanai" | sort -t'-' -k4 -V | tail -1
}

# Function to check if remote exists and update or add it
add_or_update_remote() {
  prefix=$1
  url=$2

  existing_url=$(git remote get-url $prefix 2>/dev/null)
  if [ $? -eq 0 ]; then
    if [ "$existing_url" != "$url" ]; then
      git remote remove $prefix
      git remote add $prefix $url
      echo "Updated remote $prefix to $url"
    else
      echo "Remote $prefix with URL $url already exists, skipping."
    fi
  else
    git remote add $prefix $url
    echo "Added remote $prefix with URL $url"
  fi
}

# Prompt user to find the latest tags or enter manually
read -p "Do you want to find the latest tags automatically? (yes/no): " find_latest_tags

declare -A tags

if [ "$find_latest_tags" == "no" ]; then
  # Prompt for tags with examples
  read -p "Enter AUDIO tag (e.g., AUDIO.LA.9.0.r1-05100-lanai.0): " AUDIO
  tags["AUDIO"]=${AUDIO:-AUDIO.LA.9.0.r1-05100-lanai.0}

  read -p "Enter CAMERA tag (e.g., CAMERA.LA.4.0.r2-04700-lanai.0): " CAMERA
  tags["CAMERA"]=${CAMERA:-CAMERA.LA.4.0.r2-04700-lanai.0}

  read -p "Enter CV tag (e.g., CV.LA.2.0.r1-04300-lanai.0): " CV
  tags["CV"]=${CV:-CV.LA.2.0.r1-04300-lanai.0}

  read -p "Enter DISPLAY tag (e.g., DISPLAY.LA.4.0.r2-05400-lanai.0): " DISPLAY
  tags["DISPLAY"]=${DISPLAY:-DISPLAY.LA.4.0.r2-05400-lanai.0}

  read -p "Enter GRAPHICS tag (e.g., GRAPHICS.LA.14.0.r1-05200-lanai.0): " GRAPHICS
  tags["GRAPHICS"]=${GRAPHICS:-GRAPHICS.LA.14.0.r1-05200-lanai.0}

  read -p "Enter VIDEO tag (e.g., VIDEO.LA.4.0.r2-04100-lanai.0): " VIDEO
  tags["VIDEO"]=${VIDEO:-VIDEO.LA.4.0.r2-04100-lanai.0}

  read -p "Enter LANAI tag (e.g., LA.VENDOR.14.3.0.r1-11500-lanai.0): " LANAI
  tags["LANAI"]=${LANAI:-LA.VENDOR.14.3.0.r1-11500-lanai.0}
else
  tags=(
    ["AUDIO"]="AUDIO.LA.9.0.r1-"
    ["CAMERA"]="CAMERA.LA.4.0.r2-"
    ["CV"]="CV.LA.2.0.r1-"
    ["DISPLAY"]="DISPLAY.LA.4.0.r2-"
    ["GRAPHICS"]="GRAPHICS.LA.14.0.r1-"
    ["VIDEO"]="VIDEO.LA.4.0.r2-"
    ["LANAI"]="LA.VENDOR.14.3.0.r1-"
  )
fi

repos=(
  "audio-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/audio-kernel-ar.git AUDIO"
  "bt-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/bt-kernel.git LANAI"
  "camera-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/camera-kernel.git CAMERA"
  "dataipa https://git.codelinaro.org/clo/la/platform/vendor/opensource/dataipa.git LANAI"
  "datarmnet-ext https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet-ext.git LANAI"
  "datarmnet https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet.git LANAI"
  "display-drivers https://git.codelinaro.org/clo/la/platform/vendor/opensource/display-drivers.git DISPLAY"
  "dsp-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/dsp-kernel.git LANAI"
  "eva-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/eva-kernel.git CV"
  "fingerprint https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/fingerprint.git LANAI"
  "graphics-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/graphics-kernel.git GRAPHICS"
  "mm-drivers https://git.codelinaro.org/clo/la/platform/vendor/opensource/mm-drivers.git DISPLAY"
  "mmrm-driver https://git.codelinaro.org/clo/la/platform/vendor/opensource/mmrm-driver.git VIDEO"
  "mm-sys-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/mm-sys-kernel.git LANAI"
  "securemsm-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/securemsm-kernel.git LANAI"
  "spu-kernel https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/spu-kernel.git LANAI"
  "synx-kernel https://git.codelinaro.org/clo/la/platform/vendor/opensource/synx-kernel.git LANAI"
  "touch-drivers https://git.codelinaro.org/clo/la/platform/vendor/opensource/touch-drivers.git LANAI"
  "video-driver https://git.codelinaro.org/clo/la/platform/vendor/opensource/video-driver.git VIDEO"
  "wlan/fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api.git LANAI"
  "wlan/qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0.git LANAI"
  "wlan/qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn.git LANAI"
  "wlan/platform https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/platform.git LANAI"
)

process_repo() {
  local prefix=$1
  local url=$2
  local tag_prefix=$3

  # Add or update remote
  add_or_update_remote $prefix $url

  if [ "$find_latest_tags" == "yes" ]; then
    # Get the latest tag from the remote
    latest_tag=$(get_latest_tag $url "${tags[$tag_prefix]}")

    # Skip if no valid tag is found
    if [ -z "$latest_tag" ]; then
      echo "No valid tags found for $prefix with prefix ${tags[$tag_prefix]} containing 'lanai'"
      return
    fi
  else
    latest_tag=${tags[$tag_prefix]}
  fi

  echo "Using tag $latest_tag for $prefix"

  if [ -d "$prefix" ]; then
    echo "Directory $prefix exists. Using merge method."
    git pull -s subtree -Xsubtree=$prefix $url $latest_tag --log
  else
    echo "Directory $prefix does not exist. Using import method."
    git subtree add --prefix=$prefix $url $latest_tag -m "$prefix: Import from $latest_tag"
  fi
}

for repo in "${repos[@]}"; do
  IFS=' ' read -r prefix url tag_prefix <<< "$repo"
  process_repo $prefix $url $tag_prefix
done
