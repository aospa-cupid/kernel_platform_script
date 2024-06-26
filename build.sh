#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [-c]"
  echo "  -c   Clean the build directories before starting the build."
  exit 1
}

# Function to prompt the user for LTO choice
choose_lto() {
  while true; do
    read -p "Choose LTO type (none/thin/full): " LTO_CHOICE
    case $LTO_CHOICE in
      none|thin|full)
        export LTO=$LTO_CHOICE
        break
        ;;
      *)
        echo "Invalid choice. Please choose 'thin' or 'full'."
        ;;
    esac
  done
}

# Parse command line options
CLEAN_BUILD=false
while getopts ":c" opt; do
  case $opt in
    c)
      CLEAN_BUILD=true
      ;;
    *)
      usage
      ;;
  esac
done

# Set target board platform and build variant
TARGET_BOARD_PLATFORM="pineapple"
TARGET_BUILD_VARIANT="user"

# Define paths
ANDROID_BUILD_TOP=$(pwd)
ANDROID_PRODUCT_OUT="${ANDROID_BUILD_TOP}/out/target/product/${TARGET_BOARD_PLATFORM}"
OUT_DIR="${ANDROID_BUILD_TOP}/out/msm-kernel-${TARGET_BOARD_PLATFORM}"
ENABLE_DDK_BUILD=true
KERNEL_KIT="${ANDROID_BUILD_TOP}/device/qcom/pineapple-kernel"

# Export environment variables
export TARGET_BOARD_PLATFORM
export TARGET_BUILD_VARIANT
export ANDROID_BUILD_TOP
export ANDROID_PRODUCT_OUT
export OUT_DIR
export ENABLE_DDK_BUILD
export KERNEL_KIT

# Define external modules as an array
EXT_MODULES=(
  "../vendor/qcom/opensource/mmrm-driver"
  "../vendor/qcom/opensource/mm-drivers/hw_fence"
  "../vendor/qcom/opensource/mm-drivers/msm_ext_display"
  "../vendor/qcom/opensource/mm-drivers/sync_fence"
  "../vendor/qcom/opensource/audio-kernel"
  "../vendor/qcom/opensource/camera-kernel"
  "../vendor/qcom/opensource/dataipa/drivers/platform/msm"
  "../vendor/qcom/opensource/datarmnet/core"
  "../vendor/qcom/opensource/datarmnet-ext/aps"
  "../vendor/qcom/opensource/datarmnet-ext/offload"
  "../vendor/qcom/opensource/datarmnet-ext/shs"
  "../vendor/qcom/opensource/datarmnet-ext/perf"
  "../vendor/qcom/opensource/datarmnet-ext/perf_tether"
  "../vendor/qcom/opensource/datarmnet-ext/sch"
  "../vendor/qcom/opensource/datarmnet-ext/wlan"
  "../vendor/qcom/opensource/securemsm-kernel"
  "../vendor/qcom/opensource/display-drivers/msm"
  "../vendor/qcom/opensource/eva-kernel"
  "../vendor/qcom/opensource/video-driver"
  "../vendor/qcom/opensource/graphics-kernel"
  "../vendor/qcom/opensource/touch-drivers"
  "../vendor/qcom/opensource/wlan/platform"
  "../vendor/qcom/opensource/wlan/qcacld-3.0/.kiwi_v2"
  "../vendor/qcom/opensource/bt-kernel"
  "../vendor/qcom/opensource/nfc-st-driver"
  "../vendor/qcom/opensource/eSE-driver"
  "../vendor/nxp/opensource/driver"
)

# Export external modules as a space-separated string
export EXT_MODULES="${EXT_MODULES[*]}"

# Prompt the user for LTO choice
choose_lto

# Clean the build directories if requested
if [ "$CLEAN_BUILD" = true ]; then
  echo "Cleaning build directories..."

  BUILD_DIRS=(
    "${ANDROID_BUILD_TOP}/out"
    "${ANDROID_BUILD_TOP}/kernel_platform/out"
    "${ANDROID_BUILD_TOP}/device/qcom/pineapple-kernel"
  )

  for DIR in "${BUILD_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
      echo "Removing $DIR..."
      rm -rf "$DIR"
      if [ $? -ne 0 ]; then
        echo "Failed to remove $DIR."
        exit 1
      fi
    else
      echo "$DIR does not exist, skipping."
    fi
  done
fi

# Start the kernel build process
echo "Starting the kernel build process with LTO=$LTO..."
RECOMPILE_KERNEL=1 ./kernel_platform/build/android/prepare_vendor.sh "${TARGET_BOARD_PLATFORM}" gki
if [ $? -ne 0 ]; then
  echo "Kernel build failed."
  exit 1
fi

echo "Kernel build completed successfully."
