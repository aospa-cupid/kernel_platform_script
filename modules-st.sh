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
  read -p "Enter LANAI tag (e.g., LA.VENDOR.14.3.0.r1-11500-lanai.0): " LANAI
  tags["LANAI"]=${LANAI:-LA.VENDOR.14.3.0.r1-11500-lanai.0}
else
  tags=(
    ["LANAI"]="LA.VENDOR.14.3.0.r1-"
  )
fi

repos=(
  "driver https://git.codelinaro.org/clo/la/platform/vendor/st/opensource/driver.git LANAI"
  "eSE-driver https://git.codelinaro.org/clo/la/platform/vendor/st/opensource/eSE-driver.git LANAI"
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
